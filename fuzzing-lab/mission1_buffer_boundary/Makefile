CC = gcc
CFLAGS = -std=c11 -g -O1 -fno-omit-frame-pointer -fno-pie -no-pie -fsanitize=address

.PHONY: all
all: build/target_easy

build:
	mkdir -p build

build/target_easy: src/target_easy.c src/common.h | build
	$(CC) $(CFLAGS) src/target_easy.c -o $@
