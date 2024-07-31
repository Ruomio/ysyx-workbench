VERILATOR=verilator
CSRC=$(shell find $(abspath ./csrc) -name "*.cpp" -or -name ".cc") 
VSRC=$(shell find $(abspath vsrc) -name "*.v") 
VCD_FILE=wave.vcd
ELF_FILE_NAME=$(shell echo $(VSRC) | sed -E "s/vsrc\/([a-z\-]+)\.v/V\1/g" )
BUILD_DIR=./build
OBJ_DIR=$(BUILD_DIR)/obj_dir


$(shell mkdir -p $(BUILD_DIR))

all: sim
	# @echo "Write this Makefile by your self."
	# $(VERILATOR) -cc --exe --build --trace -j 0 $(VSRC) $(CSRC)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	# @echo "Write this Makefile by your self."
	$(VERILATOR) -cc --exe --build --trace -j 8 -Mdir $(OBJ_DIR) $(VSRC) $(CSRC)


gtkwave: $(VCD_FILE)
	gtkwave $^

$(VCD_FILE):sim
	@$(ELF_FILE_NAME)


.PHONY : clean gtkwave sim

clean:
	@rm -rf $(BUILD_DIR) *.vcd

include ../Makefile
