# Mission 1. AFL++로 Heap Buffer Overflow 발견하기

권장 시간은 20분입니다. 이 Mission에서는 실제로 사용되는 Coverage-guided Fuzzer인 AFL++로 취약한 Target을 실행하고, Crash를 재현한 뒤 최소 입력을 찾습니다.

## 1. 이번 Mission의 목표

- AFL++이 Seed를 Mutation해 여러 실행 경로를 탐색하는 과정을 관찰합니다.
- ASan(AddressSanitizer)으로 Heap Buffer Overflow의 위치를 확인합니다.
- `afl-tmin`으로 오류는 유지하면서 불필요한 바이트를 제거합니다.

Target은 Heap에 16바이트를 할당하지만 입력 길이를 확인하지 않고 전부 복사합니다. 이 취약점은 실습을 위해 의도적으로 유지합니다.

## 2. 사전 준비

저장소 루트에서 설치를 마친 뒤 Mission 폴더로 이동합니다.

```bash
cd fuzzing-lab/mission1_buffer_boundary
make afl
```

`make afl`은 `afl-cc`, 디버깅 정보, ASan을 사용해 `build/target_easy`를 만듭니다. 일반 GCC 빌드가 필요하면 `make`를 사용합니다.

정상 Seed가 실행되는지 확인합니다.

```bash
ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0 \
  ./build/target_easy seeds/easy/short.txt
echo $?
```

종료 코드 `0`이면 준비가 끝났습니다.

## 3. 실행 명령어

먼저 Fuzzing 중 ASan이 일관되게 오류를 보고하도록 설정합니다.

```bash
export ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0
```

WSL에서 CPU 주파수 검사 오류가 날 때만 다음 변수를 설정합니다.

```bash
export AFL_SKIP_CPUFREQ=1
```

새 결과 폴더를 지정하고 60초 동안 실행합니다.

```bash
mkdir -p results
OUTPUT=results/afl_easy
test ! -e "$OUTPUT" || { echo "$OUTPUT 이 이미 있습니다. OUTPUT 이름을 바꾸세요."; false; }

afl-fuzz \
  -i seeds/easy \
  -o "$OUTPUT" \
  -m none \
  -V 60 \
  -- ./build/target_easy @@
```

`@@`에는 AFL++이 만든 입력 파일 경로가 자동으로 들어갑니다. `-m none`은 ASan이 사용하는 큰 가상 메모리 영역 때문에 AFL++의 메모리 제한에 걸리지 않게 합니다. 기존 결과는 자동 삭제하지 않습니다. 다시 실행할 때는 `OUTPUT=results/afl_easy_2`처럼 새 이름을 사용하세요.

Crash를 찾아 재현합니다.

```bash
ls "$OUTPUT/default/crashes"
CRASH_FILE=$(find "$OUTPUT/default/crashes" \
  -maxdepth 1 -type f -name 'id:*' -print -quit)
test -n "$CRASH_FILE" || { echo '이번 실행에서는 Crash를 발견하지 못했습니다.'; false; }
wc -c "$CRASH_FILE"

ASAN_OPTIONS=abort_on_error=1:symbolize=1:detect_leaks=0 \
  ./build/target_easy "$CRASH_FILE"
```

이제 Crash를 유지하는 최소 입력을 만듭니다.

```bash
ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0 \
  afl-tmin \
  -i "$CRASH_FILE" \
  -o results/minimized.bin \
  -m none \
  -- ./build/target_easy @@

wc -c "$CRASH_FILE" results/minimized.bin

ASAN_OPTIONS=abort_on_error=1:symbolize=1:detect_leaks=0 \
  ./build/target_easy results/minimized.bin
```

## 4. 실행하면 확인할 화면이나 결과

AFL++ 화면에서 다음 항목을 찾습니다. 버전에 따라 이름이 조금 다를 수 있습니다.

- `execs_done`: Target을 실행한 총횟수
- `saved_crashes`: 저장한 고유 Crash 입력 수
- `corpus_count`: 보관 중인 흥미로운 입력 수
- `coverage`: 탐색한 코드 경로에 관한 지표

재현하면 ASan 출력에 `heap-buffer-overflow`와 오류가 발생한 소스 위치가 나타나야 합니다. `afl-tmin` 결과의 기대 크기는 **17바이트**이며, 최소화한 입력도 같은 오류를 일으켜야 합니다.

AFL++이 저장한 고유 Crash 수와 실제 취약점 수는 같은 개념이 아닙니다. 서로 다른 입력 여러 개가 하나의 코드 오류를 일으킬 수 있습니다.

## 5. 학생이 수행할 작업

1. AFL++을 실행하고 실행 횟수와 Crash 수를 기록합니다.
2. `crashes/`에서 입력 하나를 골라 크기를 확인합니다.
3. 그 입력을 Target에 직접 전달해 ASan 오류를 재현합니다.
4. `afl-tmin`을 실행하고 최소화 전후 크기를 비교합니다.
5. `src/common.h`에서 할당 크기와 복사 반복문을 찾아 원인을 설명합니다.

## 6. 생각해 볼 질문

1. 입력이 16바이트일 때는 안전하지만 17바이트일 때 오류가 나는 이유는 무엇인가요?
2. Fuzzer가 처음 발견한 입력이 최소 Crash 입력이 아닌 이유는 무엇인가요?
3. `saved_crashes`가 2여도 취약점이 반드시 2개라고 할 수 없는 이유는 무엇인가요?
4. Coverage Feedback은 다음에 Mutation할 입력을 선택하는 데 어떤 도움을 줄까요?

## 7. 제출 항목

- AFL++ 실행 화면
- 발견된 Crash 파일의 크기
- `afl-tmin` 적용 전후 크기
- `heap-buffer-overflow`가 포함된 ASan 오류 로그
- 16바이트 버퍼와 17바이트 입력의 관계 설명

## 8. 자주 발생하는 오류와 해결법

- `afl-cc: command not found`: 저장소 루트의 `./setup.sh --mock`을 실행하거나 Ubuntu에서 `sudo apt install afl++ clang llvm`을 실행합니다.
- CPU 주파수 관련 오류: WSL에서 `export AFL_SKIP_CPUFREQ=1`을 설정한 뒤 다시 실행합니다.
- `core_pattern` 또는 외부 Crash 처리기 오류: 오류 메시지가 실제로 표시될 때만 `export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1`을 설정합니다. 이 변수는 검사를 건너뛰므로 원인을 확인하지 않고 항상 설정하지 않습니다.
- Output 폴더가 이미 존재함: 기존 폴더를 지우지 말고 `OUTPUT=results/afl_easy_2`처럼 새 경로를 사용합니다.
- 60초 안에 Crash 미발견: 이는 “취약점 없음”이 아니라 “이번 실행에서 미발견”입니다. 새 결과 경로로 다시 실행합니다.
- ASan 심볼 이름이 보이지 않음: Fuzzing 때는 `symbolize=0`을 쓰고, Crash를 직접 재현할 때 `symbolize=1`을 사용합니다.
