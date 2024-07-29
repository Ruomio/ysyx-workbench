VERILATOR=verilator
CSRC=$(shell ls csrc/*.cpp) 
VSRC=$(shell ls vsrc/*.v) 
VCD_FILE=wave.vcd
ELF_FILE_NAME=$(shell echo $(VSRC) | sed -E "s/vsrc\/([a-z\-]+)\.v/V\1/g" )

all:
	# @echo "Write this Makefile by your self."
	# $(VERILATOR) -cc --exe --build --trace -j 0 $(VSRC) $(CSRC)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	# @echo "Write this Makefile by your self."
	$(VERILATOR) -cc --exe --build --trace -j 0 $(VSRC) $(CSRC)


gtkwave: $(VCD_FILE)
	gtkwave $^

$(VCD_FILE):sim
	./obj_dir/$(ELF_FILE_NAME)


.PHONY : clean gtkwave sim

clean:
	@rm -rf obj_dir *.vcd

include ../Makefile
