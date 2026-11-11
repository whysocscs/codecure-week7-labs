# Mission 1. AFL++로 Heap Buffer Overflow 찾기

**권장 시간: 20분**

AFL++로 `target_easy`를 Coverage-guided Fuzzing하고, 발견된 Crash를 AddressSanitizer로 재현한 뒤 `afl-tmin`으로 최소화합니다.

## 1. AFL++ Target 빌드

저장소 루트에서 `./setup.sh`를 먼저 완료한 뒤 이 폴더로 이동합니다.

```bash
cd fuzzing-lab/mission1_buffer_boundary
make afl
```

`make afl`은 기존 `build` 결과를 지우고 `afl-cc`와 AddressSanitizer로 Target을 다시 빌드합니다. 정상 Seed로 실행되는지 확인합니다.

```bash
ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0 \
  ./build/target_easy seeds/easy/short.txt
echo $?
```

종료 코드 `0`이 나오면 준비가 된 것입니다.

## 2. AFL++ 실행

```bash
export ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0
export AFL_SKIP_CPUFREQ=1
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
mkdir -p results

afl-fuzz \
  -i seeds/easy \
  -o results/afl_easy \
  -m none \
  -V 60 \
  -- ./build/target_easy @@
```

`@@` 자리에는 AFL++이 생성한 입력 파일 경로가 자동으로 들어갑니다. `-m none`은 64비트 AddressSanitizer가 예약하는 큰 가상 메모리 영역 때문에 정상 실행이 차단되지 않도록 합니다. `AFL_SKIP_CPUFREQ=1`은 WSL에서 CPU 주파수 설정을 바꿀 수 없을 때 검사를 건너뜁니다. `AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1`은 Ubuntu/WSL의 외부 Core Dump 처리 설정 때문에 교육용 Fuzzing이 시작되지 않는 경우를 피합니다.

실행 화면에서 다음 항목을 관찰하세요. AFL++ 버전에 따라 이름은 조금 다를 수 있습니다.

- `execs_done`: 실행한 테스트 횟수
- `saved_crashes`: 저장된 고유 Crash 입력 수
- `corpus_count`: 보관 중인 흥미로운 입력 수
- `coverage`: 탐색한 코드 경로에 관한 지표

고유 Crash 입력 수가 서로 다른 취약점 수를 뜻하지는 않습니다. 같은 원인의 입력이 여러 개 저장될 수 있습니다. 기존 `results/afl_easy`가 있어 AFL++이 시작되지 않으면 결과를 보존한 채 `results/afl_easy_2`처럼 새 출력 경로를 사용하세요.

## 3. Crash 확인 및 재현

```bash
ls results/afl_easy/default/crashes/

CRASH_FILE=$(find results/afl_easy/default/crashes \
  -maxdepth 1 -type f -name 'id:*' -print -quit)
test -n "$CRASH_FILE" || { echo '저장된 Crash가 없습니다.'; exit 1; }
wc -c "$CRASH_FILE"

ASAN_OPTIONS=abort_on_error=1:symbolize=1:detect_leaks=0 \
  ./build/target_easy "$CRASH_FILE"
```

재현에 성공하면 AddressSanitizer가 `heap-buffer-overflow`를 보고하고 프로그램은 비정상 종료합니다. `results/afl_easy/default/fuzzer_stats`에는 전체 실행 통계가 저장됩니다.

## 4. Crash 입력 최소화

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

이 Target은 16바이트를 할당하고 길이 검증 없이 입력을 복사합니다. 따라서 기대하는 최소 Crash 입력 길이는 17바이트입니다. 실제 결과를 확인하고 `src/common.h`의 할당 크기 및 반복문 조건과 연결해 설명하세요.

## 질문

1. AFL++은 몇 번의 테스트를 실행했으며 몇 개의 Crash 입력을 저장했나요?
2. 최초 Crash 입력과 최소화된 입력의 크기는 각각 몇 바이트인가요?
3. ASan이 보고한 오류 유형과 소스 위치는 무엇인가요?
4. 최소 Crash 길이와 할당된 버퍼 크기는 어떤 관계인가요?
5. AFL++의 Coverage feedback은 입력을 탐색하는 데 어떤 역할을 하나요?

## 제출 항목

1. AFL++ 실행 화면
2. 발견된 Crash 입력의 크기
3. `afl-tmin` 적용 후 입력 크기
4. ASan 오류 로그
5. Heap Buffer Overflow 발생 원인 설명

실습은 제공된 로컬 Target에서만 진행하세요. Target 소스 수정과 기존 `tools/fuzz.py`, `mission1_generate.py`는 이 Mission의 필수 과정이 아닙니다.
