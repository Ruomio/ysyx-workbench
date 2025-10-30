AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
           riscv/ysyxsoc/ioe.c \
           riscv/ysyxsoc/timer.c \
           riscv/ysyxsoc/input.c \
           riscv/ysyxsoc/cte.c \
           riscv/ysyxsoc/gpu.c \
           riscv/ysyxsoc/bootloader.c \
           riscv/ysyxsoc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
CFLAGS    += -I$(AM_HOME)/am/src/riscv/ysyxsoc/include
LDSCRIPTS += $(AM_HOME)/scripts/linker-ysyxsoc.ld
LDFLAGS   += --defsym=_pmem_start=0x30000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e fsbl

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = The insert-arg rule in Makefile will insert mainargs here.
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=\""$(MAINARGS_PLACEHOLDER)"\"

insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) "$(MAINARGS_PLACEHOLDER)" "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
#@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents --set-start 0x30000000 --gap-fill 0xff --pad-to 0x30000000 -O binary $(IMAGE).elf $(IMAGE).bin
	@$(OBJCOPY) -S -j .fsbl -O binary $(IMAGE).elf $(IMAGE)_fsbl.bin
	@$(OBJCOPY) -S -j .ssbl -O binary $(IMAGE).elf $(IMAGE)_ssbl.bin
	@$(OBJCOPY) -S -j .text -O binary $(IMAGE).elf $(IMAGE)_text.bin
	@$(OBJCOPY) -S -j .rodata -O binary $(IMAGE).elf $(IMAGE)_rodata.bin
	@$(OBJCOPY) -S -j .data -O binary $(IMAGE).elf $(IMAGE)_data.bin
	@$(OBJCOPY) -S -j .bss -O binary $(IMAGE).elf $(IMAGE)_bss.bin
	@cat $(IMAGE)_fsbl.bin $(IMAGE)_ssbl.bin $(IMAGE)_text.bin $(IMAGE)_rodata.bin $(IMAGE)_data.bin $(IMAGE)_bss.bin > $(IMAGE).bin
#@$(OBJCOPY) -j .text -j .rodata -j .data -j .bss -O binary $(IMAGE).elf $(IMAGE).bin

run: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) run ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin

gdb: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) gdb ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin

lldb: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) lldb ARGS="$(NEMUFLAGS)" IMG=$(IMAGE).bin

gtkwave: insert-arg
	$(MAKE) -C $(NPC_HOME) gtkwave

.PHONY: insert-arg
