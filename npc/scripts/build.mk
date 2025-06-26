.DEFAULT_GOAL = all

VERILATOR=verilator
VERILATOR_CFLAGS += -MMD -cc \
					-j 16 --threads 1  \
					-O3 --x-assign fast --x-initial fast --noassert --trace \
					--timescale "1ns/1ns" --no-timing


NXDC_FILES = constr/top.nxdc

# CSRC=$(shell find csrc -name "*.c")
# CPPSRC=$(shell find csrc -name "*.cpp")
# HSRC=$(shell find $(abspath ./include) -name "*.h")
# # CSRC=$(shell find csrc -name "*.cpp" -or -name "*.c")
# INC_PATH += $(shell find $(abspath ./) -type d -name "include")
#
# ifeq ($(SOC_EN), 1)
# VINC_PATH += $(shell find $(ysyxSoC_HOME)/perip -type d -name "rtl")
# VINC_PATH += $(shell find $(ysyxSoC_HOME)/perip -type d -name "efabless")
#
# VSRC += $(shell find $(ysyxSoC_HOME)/perip -name "*.v")
# VSRC += $(shell find $(ysyxSoC_HOME)/build -name "*.v")
# endif
# VINC_PATH += $(shell find $(NPC_HOME) -type d -name "vsrc")
#
# VSRC += $(shell find $(abspath vsrc) -maxdepth 1 -name "*.v")
VCD_FILE=build/wave.vcd
ELF_FILE_NAME=$(shell echo $(VSRC) | sed -E "s/vsrc\/([a-z\-]+)\.v/build\/obj_dir\/V\1/g" )
BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj_dir
BIN=$(BUILD_DIR)/$(TOPNAME)

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
TOPNAME=ysyxSoCFull
CXXFLAGS += -DysyxSoCFull
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
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

CSRC += $(SRC_AUTO_BIND)
# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk
endif

# include dir
ifeq ($(SOC_EN), 1)
VINC_PATH += $(shell find $(ysyxSoC_HOME)/perip -type d -name "rtl")
VINC_PATH += $(shell find $(ysyxSoC_HOME)/perip -type d -name "efabless")
endif
VINC_PATH += $(shell find . -maxdepth 1 -type d -name "vsrc")

INC_PATH += $(abspath $(shell find . -type d -name "include"))
INC_PATH += $(shell find /usr/share/verilator/include -type d)
INC_PATH += $(abspath $(OBJ_DIR))


# project source
ifeq ($(SOC_EN), 1)
VSRC += $(shell find $(ysyxSoC_HOME)/perip -name "*.v")
VSRC += $(shell find $(ysyxSoC_HOME)/build -name "*.v")
endif
VSRC += $(shell find vsrc -maxdepth 1 -name "*.v")

CSRC += $(shell find csrc -name "*.c" -or -name "*.cc" -or -name "*.cpp")
V_CSRC += $(notdir $(shell find $(OBJ_DIR) -name "*.cpp"))
#
# # parameters
override ARGS ?= --log=$(BUILD_DIR)/npc-log.txt
override ARGS += --diff=$(DIFFTEST_REF_SO) $(NPCFLAGS)
override IMG +=


# CSRC_NODIR := $(notdir $(CSRC))
OBJS = $(CSRC:%.c=$(OBJ_DIR)/%.o) $(CSRC:%.cc=$(OBJ_DIR)/%.o) $(CSRC:%.cpp=$(OBJ_DIR)/%.o)
V_OBJS = $(V_CSRC:%.cpp=$(OBJ_DIR)/%.o)

CFLAGS += $(addprefix -I,$(INC_PATH)) -MMD -MP
CXXFLAGS += $(addprefix -I,$(INC_PATH)) -MMD -MP
LDFLAGS += -L$(OBJ_DIR) -lverilated -lV$(TOPNAME)

VERILATOR_CFLAGS += $(addprefix -I, $(VINC_PATH))

$(OBJ_DIR)/%.o: %.c
	@echo + CC $<
	@mkdir -p $(dir $@)
	@g++ $(CFLAGS) -c $< -o $@
	$(call call_fixdep, $(@:.o=.d), $@)
$(OBJ_DIR)/%.o: %.cc
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@g++ $(CXXFLAGS) -c $< -o $@
	$(call call_fixdep, $(@:.o=.d), $@)
$(OBJ_DIR)/%.o: %.cpp
	@echo + CXX $<
	@echo + $(CXXFLAGS)
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
# -include $(OBJS:.o=.d)
# -include $(V_OBJS:.o=.d)

all: $(BIN)

$(BIN): v_to_cpp
	make link

v_to_cpp: $(VSRC)
	@cp /usr/share/verilator/include/verilated{.cpp,_threads.cpp,_vcd_c.cpp} $(OBJ_DIR)
	@verilator $(VERILATOR_CFLAGS) --top-module $(TOPNAME) $^  -Mdir $(OBJ_DIR)
	@make -s -C $(OBJ_DIR) -f V$(TOPNAME).mk

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	# @echo "Write this Makefile by your self.!"
	$(VERILATOR) -cc --exe --build --trace -j 8 -Mdir $(OBJ_DIR) $(VSRC) $(CSRC)

ifeq ($(NVBOARD_ENABLE), 1)
link: $(OBJS) $(V_OBJS) $(NVBOARD_ARCHIVE)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo + LD
	@g++ $(LDFLAGS) $^ -o build/$(TOPNAME)

# $(BIN): $(VSRC) $(CSRC) $(CPPSRC) $(HSRC) $(NVBOARD_ARCHIVE) $(SRC_AUTO_BIND)
# 	@echo $(NVBOARD_ENABLE) $(TOPNAME)
# 	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
# 	@$(VERILATOR) $(VERILATOR_CFLAGS) \
# 		--top-module $(TOPNAME) $(VSRC) $(CSRC) $(CPPSRC) $(NVBOARD_ARCHIVE) \
# 		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
# 		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
else
link: $(OBJS) $(V_OBJS)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo + LD
	@g++ $(LDFLAGS) $^ -o build/$(TOPNAME)
# $(BIN): $(VSRC) $(CSRC) $(CPPSRC) $(HSRC)
# 	@echo $(NVBOARD_ENABLE) $(TOPNAME)
# 	@$(call git_commit, "sim NPC") # DO NOT REMOVE THIS LINE!!!
# 	@$(VERILATOR) $(VERILATOR_CFLAGS) \
# 		--top-module $(TOPNAME) $(VSRC) $(CSRC) $(CPPSRC) \
# 		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
# 		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
endif

perf: $(BIN)
	$(call git_commit, "perf NPC")
	@date | tee -a build/perf.log ;
	@if make -s -C $(AM_HOME)/../yosys-sta sta  > /dev/null ;then \
		cat $(AM_HOME)/../yosys-sta/result/ysyx_24080020-500MHz/sta.log | grep -B 1 -A 8 "Endpoint" | tee -a build/perf.log ; \
		echo "" | tee -a build/perf.log ; \
		cat $(AM_HOME)/../yosys-sta/result/ysyx_24080020-500MHz/yosys.log | grep -A 2 "Chip area for top module '\\\ysyx_24080020'" | tee -a build/perf.log ; \
	else \
		$(shell echo "yosys-sta failed"); \
	fi
	@time make -s -C $(AM_HOME)/../am-kernels/benchmarks/microbench/ \
		ARCH=riscv32e-ysyxsoc run NEMUFLAGS="-b" mainargs=test \
		| grep "\\[.* statistic\\]" | tee -a build/perf.log

gtkwave: $(VCD_FILE)
	gtkwave $^

$(VCD_FILE):
	@$(ELF_FILE_NAME)

run: $(BIN)
	@$^ $(ARGS) $(IMG)
	$(call git_commit, "run NPC")

gdb: $(BIN)
	$(call git_commit, "gdb NPC")
	gdb -s $(BIN) --args $(BIN) $(ARGS) $(IMG)

lldb: $(BIN)
	$(call git_commit, "lldb NPC")
	lldb -- $(BIN) $(ARGS) $(IMG)

.PHONY: all clean gtkwave sim nvboard run perf

clean:
	@rm -rf $(BUILD_DIR) *.vcd

# test single compile
OBJ_DIR_TEST = build/obj_dir_test
$(shell mkdir -p $(OBJ_DIR_TEST))

VINC_DIR = $(addprefix -I, $(VINC_PATH))
V_FLAGS = $(VINC_DIR) --MMD --cc -j 0  --trace-vcd --timescale "1ns/1ns" --no-timing -DCONFIG_DPIC
# V_FLAGS = $(VINC_DIR) $(VERILATOR_CFLAGS)
V_FLAGS += --top-module $(TOPNAME)

CINC_DIR = $(shell find $(abspath .) -type d -name "include")
CINC_DIR += $(abspath $(OBJ_DIR_TEST))
CINC_DIR += $(shell find /usr/share/verilator/include -type d)

CPPSRC_TEST = $(shell find csrc -name "*.cpp")
CCSRC_TEST = $(shell find csrc -name "*.cc")
CSRC_TEST = $(shell find csrc -name "*.c")
V_SRC_TEST = $(notdir $(shell find $(OBJ_DIR_TEST) -name "*.cpp"))

OBJS_TEST = $(CPPSRC_TEST:%.cpp=$(OBJ_DIR_TEST)/%.o) \
			$(CCSRC_TEST:%.cc=$(OBJ_DIR_TEST)/%.o) \
			$(CSRC_TEST:%.c=$(OBJ_DIR_TEST)/%.o)

V_OBJS_TEST = $(V_SRC_TEST:%.cpp=$(OBJ_DIR_TEST)/%.o);

C_FLAGS = $(addprefix -I, $(CINC_DIR)) -DysyxSoCFull -D__GUEST_ISA__=$(GUEST_ISA) -MMD -MP
LD_FLAGS_TEST = -lreadline -ldl -pie $(shell llvm-config --libs) \
				-L$(OBJ_DIR_TEST) -lV$(TOPNAME) -lverilated

print:
	@echo $(C_FLAGS) ----
	@echo $(CPPSRC_TEST) ----
	@echo $(OBJS_TEST) ----
	@echo $(LIBS) ----

sv: $(VSRC)
	@cp /usr/share/verilator/include/verilated{.cpp,_threads.cpp,_vcd_c.cpp} $(OBJ_DIR_TEST)
	@verilator $(V_FLAGS) $^  -Mdir $(OBJ_DIR_TEST)
	@make -s -C $(OBJ_DIR_TEST) -f V$(TOPNAME).mk

$(OBJ_DIR_TEST)/%.o: $(OBJ_DIR_TEST)/%.cpp
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@g++ $(C_FLAGS) -c $< -o $@

$(OBJ_DIR_TEST)/%.o: %.cpp
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@g++ $(C_FLAGS) -c $< -o $@

$(OBJ_DIR_TEST)/%.o: %.cc
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@g++ $(C_FLAGS) -c $< -o $@

$(OBJ_DIR_TEST)/%.o: %.c
	@echo + CXX $<
	@mkdir -p $(dir $@)
	@g++ $(C_FLAGS) -c $< -o $@

test_bin: $(OBJS_TEST) $(V_OBJS_TEST)
	@echo + LD $@
	@g++ $(LD_FLAGS_TEST) $^ -o build/$(TOPNAME)

test: sv
	make test_bin

-include $(OBJS_TEST:.o=.d)
-include $(V_OBJS_TEST:.o=.d)
