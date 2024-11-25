CC = gcc
CFLAGS = -Wall -Wextra -I./include
SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin
TEST_DIR = tests

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(filter-out $(OBJ_DIR)/test_main.o, $(SRCS:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o))
TEST_OBJS = $(filter-out $(OBJ_DIR)/main.o, $(SRCS:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o))
TARGET = $(BIN_DIR)/c-wire
TEST_TARGET = $(BIN_DIR)/test_c-wire

all: $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p $(BIN_DIR)
	$(CC) $(OBJS) -o $(TARGET)

test: $(TEST_TARGET)
	./$(TEST_TARGET)

$(TEST_TARGET): $(TEST_OBJS)
	@mkdir -p $(BIN_DIR)
	$(CC) $(TEST_OBJS) -o $(TEST_TARGET)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)

.PHONY: all clean test
