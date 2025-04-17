CC = g++
CFLAGS = -std=c++11 -Wall -Wextra -pedantic
BUILD_DIR = build

INC_PATH = $(shell find include -type d -name "*")
INCLUDES = $(addprefix -I, $(INC_PATH))

# Define the source files
SRCS = $(shell find src -name "*.cpp")
# Define the object files
OBJS = $(SRCS:%.cpp=$(BUILD_DIR)/%.o)


ifeq ($(DEBUG), 1)
CFLAGS += -g
else
CFLAGS += -O2
endif

# Define the executable name
BIN = $(BUILD_DIR)/cachesim
.DEFAULT_GOAL = $(BIN)


$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	@echo + CC $^
	@$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(BIN): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	@$(CC) $(INCLUDES) $(CFLAGS) -o $@ $^


run: $(BIN)
	@$(call git_commit, "run CacheSim")
	@$(BIN) $(NEMU_HOME)/build/insts.txt $(SIZE) $(NUM) $(WAY)

gdb:
	@$(call git_commit, "gdb CacheSim")
	gdb --args $(BIN) $(NEMU_HOME)/build/insts.txt $(SIZE) $(NUM)

clean:
	rm -rf build

.PHONY: clean run gdb


-include ../Makefile
