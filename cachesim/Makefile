CC = g++

CFLAGS = -std=c++11 -Wall -Wextra -pedantic -O2

BUILD_DIR = build


INC_PATH = $(shell find include -type d -name "*")
INCLUDES = $(addprefix -I, $(INC_PATH))

# Define the source files
SRCS = $(shell find src -name "*.cpp")
# Define the object files
OBJS = $(SRCS:%.cpp=$(BUILD_DIR)/%.o)

# Define the executable name
BIN = $(BUILD_DIR)/cachesim
.DEFAULT_GOAL = $(BIN)


$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $@

$(BIN): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(INCLUDES) $(CFLAGS) -o $@ $^ 


run:
	$(BIN) $(NEMU_HOME)/build/insts.txt

clean:
	rm -rf build

.PHONY: clean run


-include ../Makefile