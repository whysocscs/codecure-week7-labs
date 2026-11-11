CC = gcc
CFLAGS = -std=c11 -g -O1 -fno-omit-frame-pointer -fno-pie -no-pie -fsanitize=address

.PHONY: all afl clean
all: build/target_easy

afl:
	@command -v afl-cc >/dev/null 2>&1 || { echo "오류: afl-cc를 찾을 수 없습니다. 저장소 루트에서 ./setup.sh --mock을 실행하세요." >&2; exit 1; }
	$(MAKE) clean
	$(MAKE) CC=afl-cc all

clean:
	rm -rf build

build:
	mkdir -p build

build/target_easy: src/target_easy.c src/common.h | build
	@command -v $(CC) >/dev/null 2>&1 || { echo "오류: 컴파일러 '$(CC)'를 찾을 수 없습니다." >&2; exit 1; }
	$(CC) $(CFLAGS) src/target_easy.c -o $@
