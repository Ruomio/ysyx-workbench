VERILATOR=verilator
CSRC=$(shell ls csrc/*.cpp) 
VSRC=$(shell ls vsrc/*.v) 

all:
	# @echo "Write this Makefile by your self."
	$(VERILATOR) -cc --exe --build --trace -j 0 $(VSRC) $(CSRC)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	# @echo "Write this Makefile by your self."
	$(VERILATOR) -cc --exe --build --trace -j 0 $(VSRC) $(CSRC)


gtkwave: $(shell ls *.vcd)
	gtkwave $^

.PHONY : clean gtkwave sim

clean:
	@rm -rf obj_dir *.vcd

include ../Makefile
