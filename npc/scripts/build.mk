.DEFAULT_GOAL = all

VERILATOR=verilator
VERILATOR_CFLAGS += -MMD -cc \
					-j 16 --threads 1  \
					-O3 --x-assign fast --x-initial fast --noassert --trace-fst \
					--timescale "1ns/1ns" --no-timing
VERILATOR_RUNTIME_ARGS += +verilator+rand+reset+2

NXDC_FILES = constr/top.nxdc

VCD_FILE=build/wave.vcd
ELF_FILE_NAME=$(shell echo $(VSRC) | sed -E "s/vsrc\/([a-z\-]+)\.v/build\/obj_dir\/V\1/g" )
BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj_dir
BIN=$(BUILD_DIR)/$(TOPNAME)

VERILOG_TARGET=$(BUILD_DIR)/ysyx_24080020.v

$(shell mkdir -p $(OBJ_DIR))


ifdef CONFIG_ITRACE
include $(NPC_HOME)/csrc/utils/filelist.mk
endif

# Extract variabls from environment, decide to select NPC OR SOC
ifeq ($(ARCH), riscv32e-ysyxsoc)
TOPNAME=ysyxSoCFull
CXXFLAGS += -DysyxSoCFull
else ifeq ($(ARCH), riscv32e-npc)
TOPNAME=ysyx_24080020_NPC
CXXFLAGS += -Dysyx_24080020_NPC -UCONFIG_NVBOARD
else
# TOPNAME=ysyxSoCFull
# CXXFLAGS += -DysyxSoCFull
TOPNAME=ysyx_24080020_NPC
CXXFLAGS += -Dysyx_24080020_NPC -UCONFIG_NVBOARD
$(echo "default ARCH is riscv32e-ysyxsoc")
endif

ifdef CONFIG_NVBOARD
ifeq ($(ARCH), riscv32e-npc)
NVBOARD_ENABLE := 0
else
NVBOARD_ENABLE := 1
endif
else
NVBOARD_ENABLE := 0
endif

ifeq ($(NVBOARD_ENABLE), 1)
# constraint file
SRC_AUTO_BIND = $(BUILD_DIR)/auto_bind.cpp
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

CSRC += $(SRC_AUTO_BIND)
# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk
endif

# include dir
ifeq ($(SOC_EN), 1)
SOC_VINC_PATH += $(shell find ../ysyxSoC/perip -type d -name "rtl")
SOC_VINC_PATH += $(shell find ../ysyxSoC/perip -type d -name "efabless")
endif
VINC_PATH += $(shell find . -maxdepth 1 -type d -name "vsrc")

INC_PATH += $(shell find $(abspath include) -type d -name "include")
INC_PATH += $(shell find /usr/share/verilator/include -type d)
INC_PATH += $(abspath $(OBJ_DIR))


# project source
ifeq ($(SOC_EN), 1)
SOC_VSRC += $(shell find ../ysyxSoC/perip -name "*.v")
SOC_VSRC += $(shell find ../ysyxSoC/build -name "ysyxSoCFull.v")
endif
VSRC += $(shell find vsrc -maxdepth 1 -name "*.v")

CSRC += $(shell find csrc -name "*.c" -or -name "*.cpp")
V_CSRC += $(notdir $(shell find $(OBJ_DIR) -name "*.cpp"))



# verilator system files
VERILATOR_SYS_FILES := verilated.cpp verilated_threads.cpp verilated_vcd_c.cpp
VERILATOR_SYS_TARGETS := $(addprefix $(OBJ_DIR)/,$(VERILATOR_SYS_FILES))



#
# # parameters
override ARGS ?= --log=$(BUILD_DIR)/npc-log.txt
override ARGS += --diff=$(DIFFTEST_REF_SO) $(NPCFLAGS)
override IMG +=


# CSRC_NODIR := $(notdir $(CSRC))
TMP_C = $(filter %.c, $(CSRC))
TMP_CC = $(filter %.cc, $(CSRC))
TMP_CPP = $(filter %.cpp, $(CSRC))
OBJS += $(TMP_C:%.c=$(OBJ_DIR)/%.o) $(TMP_CC:%.cc=$(OBJ_DIR)/%.o) $(TMP_CPP:%.cpp=$(OBJ_DIR)/%.o)
V_OBJS += $(V_CSRC:%.cpp=$(OBJ_DIR)/%.o)

CFLAGS += $(addprefix -I,$(INC_PATH)) -MMD -MP
CXXFLAGS += $(addprefix -I,$(INC_PATH)) -MMD -MP
# LDFLAGS += -L$(OBJ_DIR) -lverilated -lV$(TOPNAME)

# VERILATOR_CFLAGS += --lint-only -Wall -fno-const
VERILATOR_CFLAGS += $(addprefix -I, $(VINC_PATH)) $(addprefix -I, $(SOC_VINC_PATH))

$(OBJ_DIR)/%.o: %.c
	@echo + CC $<
	@mkdir -p $(dir $@)
	@g++ $(CXXFLAGS) -c $< -o $@
	$(call call_fixdep, $(@:.o=.d), $@)
$(OBJ_DIR)/%.o: %.cc
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@g++ $(CXXFLAGS) -c $< -o $@
	$(call call_fixdep, $(@:.o=.d), $@)
$(OBJ_DIR)/%.o: %.cpp
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@g++ $(CXXFLAGS) -c $< -o $@
	$(call call_fixdep, $(@:.o=.d), $@)
$(OBJ_DIR)/%.o: $(OBJ_DIR)/%.cpp
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@g++ $(CXXFLAGS) -c $< -o $@
	$(call call_fixdep, $(@:.o=.d), $@)
#
# # Depencies
-include $(OBJS:.o=.d)
-include $(V_OBJS:.o=.d)

all: $(BIN)

# $(BIN): modify-config clean_obj v_to_cpp
# 	@make link

$(BIN): modify-config clean_obj classic

modify-config: $(CONF)
ifeq ($(ARCH), riscv32e-npc)
	@scripts/config --enable CONFIG_ISA_riscv32=y
	@scripts/config --set-str CONFIG_ISA "riscv32"
	@scripts/config --set-val CONFIG_MBASE 0x80000000
	@scripts/config --set-val CONFIG_MSIZE 0x20000000
	@scripts/config --disable CONFIG_PSRAM
	@scripts/config --disable CONFIG_PSRAM_BASE
	@scripts/config --disable CONFIG_PSRAM_SIZE
	@scripts/config --disable CONFIG_SDRAM
	@scripts/config --disable CONFIG_SDRAM_BASE
	@scripts/config --disable CONFIG_SDRAM_SIZE
	@scripts/config --disable CONFIG_SRAM
	@scripts/config --disable CONFIG_SRAM_BASE
	@scripts/config --disable CONFIG_SRAM_SIZE
	@scripts/config --disable CONFIG_DIFFTEST
endif
ifeq ($(ARCH), riscv32e-ysyxsoc)
	@scripts/config --enable CONFIG_ISA_riscv32=y
	@scripts/config --set-str CONFIG_ISA "riscv32"
	@scripts/config --set-val CONFIG_MBASE 0x30000000
	@scripts/config --set-val CONFIG_MSIZE 0x01000000
	@scripts/config --enable CONFIG_PSRAM
	@scripts/config --enable CONFIG_SDRAM
	@scripts/config --enable CONFIG_SRAM
	@scripts/config --set-val CONFIG_PSRAM_BASE 0x80000000
	@scripts/config --set-val CONFIG_PSRAM_SIZE 0x00400000
	@scripts/config --set-val CONFIG_SDRAM_BASE 0xa0000000
	@scripts/config --set-val CONFIG_SDRAM_SIZE 0x02000000
	@scripts/config --set-val CONFIG_SRAM_BASE 0x0f000000
	@scripts/config --set-val CONFIG_SRAM_SIZE 0x00002000
	@scripts/config --disable CONFIG_DIFFTEST
endif
	$(Q)$(CONF) $(silent) --syncconfig $(Kconfig)


$(VERILATOR_SYS_TARGETS): $(OBJ_DIR)/%: /usr/share/verilator/include/%
	@echo "[COPY] $< -> $@"
	@cp $< $@

v_to_cpp: get_v_to_cpp $(VERILATOR_SYS_TARGETS)
get_v_to_cpp: $(VERILOG_TARGET) $(SOC_VSRC)
	@verilator $(VERILATOR_CFLAGS) --top-module $(TOPNAME) $^ -Mdir $(OBJ_DIR)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	# @echo "Write this Makefile by your self.!"
	$(VERILATOR) -cc --exe --build --trace-fst -j 8 -Mdir $(OBJ_DIR) $(VSRC) $(CSRC)

ifeq ($(NVBOARD_ENABLE), 1)
link: $(OBJS) $(V_OBJS) $(NVBOARD_ARCHIVE)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo + LD $(BIN)
	@g++ $(LDFLAGS) $^ -o $(BIN)

# $(BIN): $(VSRC) $(CSRC) $(CPPSRC) $(NVBOARD_ARCHIVE) $(SRC_AUTO_BIND)
# 	@echo $(NVBOARD_ENABLE) $(TOPNAME)
# 	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
# 	@$(VERILATOR) $(VERILATOR_CFLAGS) \
# 		--top-module $(TOPNAME) $(VSRC) $(CSRC) $(CPPSRC) $(NVBOARD_ARCHIVE) \
# 		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
# 		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))


classic: $(VERILOG_TARGET) $(SOC_VSRC) $(CSRC) $(CPPSRC) $(NVBOARD_ARCHIVE)
	@echo $(NVBOARD_ENABLE) $(TOPNAME)
	@$(call git_commit, "sim NPC") # DO NOT REMOVE THIS LINE!!!
	@$(VERILATOR) $(VERILATOR_CFLAGS) --build \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

else
link: $(OBJS) $(V_OBJS)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo + LD $(BIN)
	@g++ $(LDFLAGS) $^ -o $(BIN)

# $(BIN): $(VSRC) $(CSRC) $(CPPSRC) $(HSRC)
# 	@echo $(NVBOARD_ENABLE) $(TOPNAME)
# 	@$(call git_commit, "sim NPC") # DO NOT REMOVE THIS LINE!!!
# 	@$(VERILATOR) $(VERILATOR_CFLAGS) \
# 		--top-module $(TOPNAME) $(VSRC) $(CSRC) $(CPPSRC) \
# 		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
# 		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

classic: $(VERILOG_TARGET) $(SOC_VSRC) $(CSRC) $(CPPSRC)
	@echo $(NVBOARD_ENABLE) $(TOPNAME)
	@$(call git_commit, "sim NPC") # DO NOT REMOVE THIS LINE!!!
	@$(VERILATOR) $(VERILATOR_CFLAGS) --build \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

endif



perf: $(BIN)
	$(call git_commit, "perf NPC")
	@echo "" | tee -a .log/perf.log
	@date | tee -a .log/perf.log
	@if make -s -C $(AM_HOME)/../yosys-sta sta  > /dev/null ;then \
		cat $(AM_HOME)/../yosys-sta/result/ysyx_24080020-500MHz/sta.log | grep -B 1 -A 8 "Endpoint" | tee -a .log/perf.log ; \
		echo "" | tee -a .log/perf.log ; \
		cat $(AM_HOME)/../yosys-sta/result/ysyx_24080020-500MHz/yosys.log | grep -A 2 "Chip area for top module '\\\ysyx_24080020'" | tee -a .log/perf.log ; \
	else \
		$(shell echo "yosys-sta failed"); \
	fi
	@time make -s -C $(AM_HOME)/../am-kernels/benchmarks/microbench/ \
		ARCH=$(ARCH) run NEMUFLAGS="-b" mainargs=test \
		2>&1 | grep "\\[.* statistic\\]\\|real\\|user\\|sys" | tee -a .log/perf.log


# iverilog simulation
VVP_FILE += $(BUILD_DIR)/iverilog_top.vvp
VVP_NETLIST_FILE += $(BUILD_DIR)/iverilog_netlist_top.vvp
TB_FILE += $(shell find . -type f -name "iverilog_top.v")
TB_NETLIST_FILE += $(shell find . -type f -name "iverilog_netlist_top.v")
NETLIST = $(shell find $(YSYX_HOME)/yosys-sta/result/ysyx_24080020-500MHz -type f -name "ysyx_24080020.netlist.fixed.v")
CELLS = $(shell find $(YSYX_HOME)/yosys-sta/nangate45 -type f -name "cells.v")


$(VVP_FILE): $(VERILOG_TARGET) $(TB_FILE)
	@echo "+ iverilog -> $@"
	@iverilog -g2012 -D ysyx_24080020_NPC -o $@ $^ -I $(VINC_PATH)
#@iverilog -g2012 -DMEM_FILE=\"$(IMG)\" -o $@ $(VSRC) $(TB_FILE) -I $(VINC_PATH)
# @iverilog -g2012 -DMEM_FILE=\"\\\"$(IMG)\\\"\" -o $@ $^ -I $(VINC_PATH)

# $(VVP_NETLIST_FILE): $(TB_NETLIST_FILE) $(NETLIST_FILE) $(CLEES_FILE)
$(VVP_NETLIST_FILE): $(TB_NETLIST_FILE)
	@echo "+ iverilog -> $@"
	@iverilog -g2012 -D ysyx_24080020_NPC -o $@ $^ $(NETLIST) $(CELLS)

iverilog: $(VVP_FILE)
	@$(call git_commit, "iverilog NPC")
	@echo "+ exec vvp $^"
	@vvp $^ +MEM_FILE=$(IMG)
	@if [ -f build/tb_wave.vcd ]; then \
		echo "Converting VCD to FST..."; \
		vcd2fst build/tb_wave.vcd build/tb_wave.fst; \
		echo "Removing VCD file..."; \
		rm build/tb_wave.vcd; \
	else \
		echo "VCD file not found, skipping conversion"; \
	fi

iverilog-netlist: $(VVP_NETLIST_FILE)
	@$(call git_commit, "iverilog NPC")
	@echo "+ exec vvp $^"
	@vvp $^ +MEM_FILE=$(IMG)
	@if [ -f build/tb_netlist_wave.vcd ]; then \
		echo "Converting VCD to FST..."; \
		vcd2fst build/tb_netlist_wave.vcd build/tb_netlist_wave.fst; \
		echo "Removing VCD file..."; \
		rm build/tb_netlist_wave.vcd; \
	else \
		echo "VCD file not found, skipping conversion"; \
	fi

# CI TEST
FORMAT_IMG = $(BUILD_DIR)/$(notdir $(IMG)).hex

verilog: $(VSRC)
	@python3 scripts/merge_verilog.py -o $(VERILOG_TARGET) $^
# @iverilog -g2012 -I$(VINC_PATH) -E -o $(VERILOG_TARGET) $^

$(VERILOG_TARGET): verilog
	@echo "get merged file: build/ysyx_24080020.v"

$(FORMAT_IMG):
	@bash scripts/format_image.sh $(IMG) $(FORMAT_IMG)

sim-iverilog: $(VVP_FILE) $(FORMAT_IMG)
	@vvp $(VVP_FILE) +MEM_FILE=$(FORMAT_IMG)

sim-iverilog-netlist: $(VVP_NETLIST_FILE) $(FORMAT_IMG)
	@vvp $(VVP_NETLIST_FILE) +MEM_FILE=$(FORMAT_IMG)


gtkwave: $(VCD_FILE)
	gtkwave $^

$(VCD_FILE):
	@$(ELF_FILE_NAME)

run: $(BIN)
	@$^ $(ARGS) $(IMG) $(VERILATOR_RUNTIME_ARGS)
	$(call git_commit, "run NPC")

gdb: $(BIN)
	$(call git_commit, "gdb NPC")
	gdb -s $(BIN) --args $(BIN) $(ARGS) $(IMG)

lldb: $(BIN)
	$(call git_commit, "lldb NPC")
	lldb -- $(BIN) $(ARGS) $(IMG)

.PHONY: all clean clean_obj gtkwave sim nvboard run perf verilog

clean:
	@rm -rf $(BUILD_DIR) *.vcd

clean_obj:
	@rm -rf $(OBJ_DIR)
