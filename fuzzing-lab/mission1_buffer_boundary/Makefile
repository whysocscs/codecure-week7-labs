CC = gcc
CFLAGS = -std=c11 -g -O1 -fno-omit-frame-pointer -fno-pie -no-pie -fsanitize=address

.PHONY: all afl clean
all: build/target_easy

afl: clean
	$(MAKE) CC=afl-cc all

clean:
	rm -rf build

build:
	mkdir -p build

build/target_easy: src/target_easy.c src/common.h | build
	$(CC) $(CFLAGS) src/target_easy.c -o $@
