COMMON_CFLAGS = -std=c11 -g -O0 -Wall -Wextra -Wpedantic \
	-fno-omit-frame-pointer -fno-pie -no-pie -fsanitize=address

.PHONY: all blind afl clean

all: blind afl

blind: build/target_hard_blind

afl: build/target_hard_afl

build:
	mkdir -p build

build/target_hard_blind: src/target_hard.c | build
	@command -v gcc >/dev/null 2>&1 || { echo "오류: gcc를 찾을 수 없습니다. 저장소 루트에서 ./setup.sh --mock을 실행하세요." >&2; exit 1; }
	gcc $(COMMON_CFLAGS) -DCODECURE_BLIND_FORKSERVER $< -o $@

build/target_hard_afl: src/target_hard.c | build
	@command -v afl-cc >/dev/null 2>&1 || { echo "오류: afl-cc를 찾을 수 없습니다. 저장소 루트에서 ./setup.sh --mock을 실행하세요." >&2; exit 1; }
	afl-cc $(COMMON_CFLAGS) $< -o $@

clean:
	rm -rf build
