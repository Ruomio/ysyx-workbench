VERILATOR=verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
					-O3 --x-assign fast --x-initial fast --noassert --trace

TOPNAME=top
NXDC_FILES = constr/top.nxdc
INC_PATH ?=


CSRC=$(shell find $(abspath ./csrc) -name "*.cpp" -or -name ".cc") 
VSRC=$(shell find $(abspath vsrc) -name "*.v") 
VCD_FILE=wave.vcd
ELF_FILE_NAME=$(shell echo $(VSRC) | sed -E "s/vsrc\/([a-z\-]+)\.v/build\/obj_dir\/V\1/g" )
BUILD_DIR=./build
OBJ_DIR=$(BUILD_DIR)/obj_dir
BIN=$(BUILD_DIR)/$(TOPNAME)


$(shell mkdir -p $(BUILD_DIR))

all: $(BIN)
	# @echo "Write this Makefile by your self.."
	# $(VERILATOR) -cc --exe --build --trace -j 0 $(VSRC) $(CSRC)



# constraint file
# SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# $(SRC_AUTO_BIND): $(NXDC_FILES)
# 	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
#include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""



sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	# @echo "Write this Makefile by your self."
	$(VERILATOR) -cc --exe --build --trace -j 8 -Mdir $(OBJ_DIR) $(VSRC) $(CSRC)

nvboard: $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

gtkwave: $(VCD_FILE)
	gtkwave $^

$(VCD_FILE):sim
	@$(ELF_FILE_NAME)

run: $(BIN)
	@$^

.PHONY : all clean gtkwave sim nvboard run

clean:
	@rm -rf $(BUILD_DIR) *.vcd

include ../Makefile
