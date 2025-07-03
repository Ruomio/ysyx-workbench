BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/branchsim

$(shell mkdir -p $(BUILD_DIR))

DISASM_FILE_PATH = $(YSYX_HOME)/am-kernels/benchmarks/microbench/build/microbench-riscv32e-ysyxsoc.txt
PC_STREAM_FILE_PATH = $(NEMU_HOME)/build/insts.txt

SRC = $(shell find src -type f -name "*.cpp")

INCLUDE_DIR = $(shell find include -type d)

OBJS = $(SRC:%.cpp=$(OBJ_DIR)/%.o)


CC = g++
CXX_FLAGS = $(addprefix -I, $(INCLUDE_DIR)) -MMD -MP -o2 -g
LD_FLAGS = -lreadline

.DEFAULT_GOAL = $(BIN)

$(OBJ_DIR)/%.o: %.cpp
	@echo + $(CC) $<
	@mkdir -p $(dir $@)
	@$(CC) $(CXX_FLAGS) -c $< -o $@

$(BIN): $(OBJS)
	@echo LD $^ -> $@
	@$(CC) $(LD_FLAGS) $^ -o $@

run: $(BIN)
	@$(call git_commit, "run BranchSim")
	@$(BIN) $(DISASM_FILE_PATH) $(PC_STREAM_FILE_PATH)

gdb: $(BIN)
	@$(call git_commit, "run BranchSim")
	@gdb --args $(BIN) $(DISASM_FILE_PATH) $(PC_STREAM_FILE_PATH)

clean:
	@echo rm -rf $(BUILD_DIR)
	@rm -rf $(BUILD_DIR)

.PHONY: clean run gdb

-include ../Makefile
-include $(OBJS:.o=.d)
