AM_SRCS := riscv/npc/start.S \
           riscv/npc/trm.c \
           riscv/npc/ioe.c \
           riscv/npc/timer.c \
           riscv/npc/input.c \
           riscv/npc/cte.c \
           riscv/npc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
CFLAGS    += -I$(AM_HOME)/am/src/riscv/npc/include
LDSCRIPTS += $(AM_HOME)/scripts/linker.ld
LDFLAGS   += --defsym=_pmem_start=0x80000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = The insert-arg rule in Makefile will insert mainargs here.
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=\""$(MAINARGS_PLACEHOLDER)"\"

insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) "$(MAINARGS_PLACEHOLDER)" "$(mainargs)"
	@python $(AM_HOME)/tools/insert-arg-tb.py $(IMAGE)_tb.hex $(MAINARGS_MAX_LEN) "$(MAINARGS_PLACEHOLDER)" "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin
	@echo + OBJCOPY "->" $(IMAGE_REL)_tb.hex
	@$(OBJCOPY) -S -g --set-section-flags .bss=alloc,contents -O verilog --verilog-data-width=1 $(IMAGE).elf $(IMAGE)_tb.hex
	@sed -i 's/^@80/@00/' $(IMAGE)_tb.hex
#@$(OBJCOPY) -S -g --set-section-flags .bss=alloc,contents --adjust-vma -0x80000000 -O verilog --verilog-data-width=1 $(IMAGE).elf $(IMAGE)_tb.hex
# @hexdump -v -e '1/4 "%08x\n"' $(IMAGE).bin > $(IMAGE)_tb.txt

iverilog: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) iverilog ARGS="$(NEMUFLAGS)" IMG=$(IMAGE)_tb.hex

iverilog-netlist: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) iverilog-netlist ARGS="$(NEMUFLAGS)" IMG=$(IMAGE)_tb.hex

run: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) run ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin

gdb: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) gdb ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin

lldb: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) lldb ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin

gtkwave: insert-arg
	$(MAKE) -C $(NPC_HOME) gtkwave

.PHONY: insert-arg
