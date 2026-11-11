# Mission 3. 어려운 Target에서 Blind와 Coverage-guided 비교하기

권장 시간은 20분입니다. 동일한 Seed와 동일한 Target을 AFL++의 Blind Mode와 Coverage-guided Mode로 실행해, 실행 경로 피드백이 탐색에 어떤 차이를 만드는지 실험합니다.

## 1. 이번 Mission의 목표

핵심 질문은 다음과 같습니다.

> 실행 경로 피드백이 있으면 여러 조건을 통과해야 발견할 수 있는 취약점을 더 쉽게 찾을 수 있을까?

입력 형식은 `ABCD:<payload>`입니다. Target은 `A`, `B`, `C`, `D`, `:`를 각각 중첩 조건문으로 확인한 뒤에만 Payload를 처리합니다. Payload용 Heap Buffer는 16바이트이며 17바이트 이상을 길이 검사 없이 복사하면 의도된 Heap Buffer Overflow가 발생합니다.

초기 Seed `AAAA:XXXXXXXXXXXXXXXXXXXX`는 첫 문자 조건만 통과하고 Crash를 일으키지 않습니다. Mission 2의 `AAAA`에서 `ABCD`를 찾아가는 구조가 실제 C Target과 AFL++ 실험으로 이어집니다.

## 2. 사전 준비

Mission 폴더로 이동해 두 실행 파일을 만듭니다.

```bash
cd fuzzing-lab/mission3_harder_target
make blind
make afl
```

- `build/target_hard_blind`: GCC와 ASan으로 빌드하며 Coverage 계측이 없음
- `build/target_hard_afl`: `afl-cc`와 ASan으로 빌드하며 Coverage 계측이 있음

두 파일은 같은 `-O0`, 디버깅, ASan 옵션을 사용하고 서로 다른 이름으로 공존합니다. Blind 실행 파일에는 AFL++ 4.09와 WSL2 조합에서도 `-n`이 멈추지 않도록 실행만 관리하는 호환 Forkserver가 들어 있습니다. 이 코드는 Coverage 정보를 제공하지 않습니다.

Target의 종료 코드는 다음과 같습니다.

| 종료 코드 | 의미 |
|---:|---|
| 0 | 올바른 Header와 0~16바이트 Payload를 정상 처리 |
| 2 | 너무 짧음, Header 불일치, 256바이트 초과 입력을 안전하게 거부 |
| 3 | 잘못된 실행 방법, 파일 읽기 또는 시스템 자원 오류 |
| 86 | 비교 스크립트가 ASan Crash를 AFL++에 전달할 때 사용하는 전용 코드 |

## 3. 실행 명령어

가장 간단한 방법은 자동 비교 스크립트입니다.

```bash
bash scripts/run_compare.sh --seconds 60
```

여러 번 반복하려면 다음과 같이 실행합니다. Blind와 Guided가 각각 60초씩 순서대로 실행되므로 총 Fuzzing 시간은 약 6분입니다.

```bash
bash scripts/run_compare.sh --seconds 60 --repeats 3
```

직접 두 명령을 실행하려면 먼저 공통 환경을 설정합니다.

```bash
export ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0
export AFL_CRASH_EXITCODE=86
export CODECURE_ASAN_EXITCODE=86
export AFL_DISABLE_TRIM=1
export AFL_NO_ARITH=1
export AFL_TMPDIR=/tmp
```

WSL에서 CPU 주파수 오류가 날 때만 다음을 설정합니다.

```bash
export AFL_SKIP_CPUFREQ=1
```

`core_pattern` 또는 외부 Crash 처리기 관련 오류가 실제로 표시될 때만 다음을 설정합니다.

```bash
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
```

기존 결과를 보호하기 위해 새 폴더인지 먼저 확인하고 두 모드를 실행합니다.

```bash
BLIND_OUT=results/blind
GUIDED_OUT=results/guided
test ! -e "$BLIND_OUT" || { echo "$BLIND_OUT 이 이미 있습니다."; false; }
test ! -e "$GUIDED_OUT" || { echo "$GUIDED_OUT 이 이미 있습니다."; false; }

AFL_DUMB_FORKSRV=1 afl-fuzz \
  -n \
  -D \
  -i seeds/hard \
  -x dictionary/header.dict \
  -o "$BLIND_OUT" \
  -m none \
  -V 60 \
  -- ./build/target_hard_blind @@

afl-fuzz \
  -D \
  -i seeds/hard \
  -x dictionary/header.dict \
  -o "$GUIDED_OUT" \
  -m none \
  -V 60 \
  -- ./build/target_hard_afl @@
```

`-n`은 AFL++의 비계측 모드입니다. Mutation은 수행하지만 Coverage Feedback으로 입력을 고르거나 보관하지 않습니다. `-D`는 두 모드 모두에서 같은 결정적 Mutation 단계를 사용하게 하고, `-x`는 Header에 쓰이는 한 글자 토큰만 담은 동일한 사전을 제공합니다. 완성된 `ABCD:` 입력은 사전에 없습니다. `AFL_NO_ARITH=1`은 긴 Seed의 모든 바이트에 산술 연산을 먼저 적용하느라 수업 시간이 소모되는 것을 막습니다. `AFL_DISABLE_TRIM=1`은 아직 Header를 통과하지 못한 Seed에서 Payload가 불필요한 부분으로 판단되어 잘리는 것을 막습니다. `AFL_TMPDIR=/tmp`는 반복 생성되는 현재 입력만 WSL의 Linux 파일시스템에 두어 `/mnt/c`에서의 실행 지연을 줄이며, 최종 결과는 계속 `results/`에 저장합니다. 따라서 두 모드는 같은 길이와 Mutation 재료를 사용하고, 중간 경로를 보관하는지 여부만 다릅니다. `AFL_DUMB_FORKSRV=1`은 제공된 비계측 호환 Forkserver를 사용하라는 뜻이며 Coverage를 켜는 옵션이 아닙니다.

조건 단계별 Coverage가 실제로 다른지도 확인할 수 있습니다.

```bash
mkdir -p /tmp/codecure-showmap
printf 'AAAA:1234567890123456' > /tmp/codecure-showmap/a
printf 'ABAA:1234567890123456' > /tmp/codecure-showmap/ab
printf 'ABCA:1234567890123456' > /tmp/codecure-showmap/abc
printf 'ABCD:1234567890123456' > /tmp/codecure-showmap/abcd

for stage in a ab abc abcd; do
  afl-showmap -q -e \
    -o "/tmp/codecure-showmap/map-$stage" \
    -- ./build/target_hard_afl "/tmp/codecure-showmap/$stage"
done

wc -l /tmp/codecure-showmap/map-*
sha256sum /tmp/codecure-showmap/map-*
```

Map 내용이나 해시가 단계마다 달라지면 AFL++이 중첩 조건을 서로 다른 실행 경로로 관찰한 것입니다.

## 4. 실행하면 확인할 화면이나 결과

자동 스크립트는 기존 폴더를 지우지 않고 `results/compare_날짜_시간_PID/` 아래에 매번 새 결과를 저장한 뒤 다음 표를 출력합니다.

| 항목 | Blind | Coverage-guided |
|---|---|---|
| 총 실행 횟수 | 측정값 | 측정값 |
| 발견한 Crash 수 | 측정값 | 측정값 |
| 첫 Crash 발견 여부 | 성공 또는 미발견 | 성공 또는 미발견 |
| 첫 Crash 발견 시점 | 초 또는 미발견 | 초 또는 미발견 |
| Coverage 정보 | 사용하지 않음 | 발견한 Edge 수 |

통계는 AFL++의 `fuzzer_stats`에서 읽습니다. Ubuntu의 AFL++ 4.09가 `-n` 실행에 `fuzzer_stats`를 만들지 않는 경우, 스크립트는 AFL++이 남긴 `plot_data` 마지막 행을 같은 키의 `fuzzer_stats`로 변환한 뒤 읽습니다. Guided 결과는 보통 `guided/default/fuzzer_stats`에 있습니다.

실행 시간이 같아도 컴퓨터 부하와 실행 모드 때문에 총 실행 횟수는 다를 수 있습니다. Crash가 없으면 “취약점 없음”이 아니라 **이번 실험에서 미발견**으로 해석합니다.

## 5. 학생이 수행할 작업

1. `make blind`와 `make afl`로 두 Target을 빌드합니다.
2. `afl-showmap`으로 Header 조건 통과 단계마다 Coverage가 달라지는지 확인합니다.
3. 같은 Seed와 실행 시간으로 Blind와 Guided를 실행합니다.
4. 비교표의 실행 횟수, Crash 수, 최초 Crash 시점과 Coverage를 기록합니다.
5. 가능하면 `--repeats 3`으로 반복해 Crash 발견 횟수를 비교합니다.
6. 발견한 Crash 하나를 ASan으로 재현하고 `heap-buffer-overflow`를 확인합니다.

Guided Crash 재현 예시:

```bash
CRASH_FILE=$(find results -path '*/guided/default/crashes/id:*' -print -quit)
test -n "$CRASH_FILE" || { echo 'Guided Crash가 아직 없습니다.'; false; }

ASAN_OPTIONS=abort_on_error=1:symbolize=1:detect_leaks=0 \
  ./build/target_hard_afl "$CRASH_FILE"
```

## 6. 생각해 볼 질문

1. `ABAA`, `ABCA`처럼 더 깊은 조건에 도달한 입력을 보관하면 왜 유리한가요?
2. Blind Mode도 원리적으로 Crash 입력을 만들 수 있는 이유는 무엇인가요?
3. 같은 60초 동안 두 모드의 총 실행 횟수가 다를 수 있는 이유는 무엇인가요?
4. 한 번의 결과만으로 Coverage-guided 방식이 언제나 빠르다고 말할 수 없는 이유는 무엇인가요?
5. Seed가 이미 `ABCD:`로 시작한다면 비교 결과는 어떻게 달라질까요?

## 7. 제출 항목

- 두 Target 빌드 결과
- 단계별 `afl-showmap` 차이를 보여 주는 결과
- Blind/Guided 비교표와 사용한 실행 시간·반복 횟수
- Crash 발견 횟수와 첫 Crash 시점
- 발견한 Crash의 ASan `heap-buffer-overflow` 로그
- Coverage Feedback이 실험 결과에 미친 영향과 실험의 한계 설명

## 8. 자주 발생하는 오류와 해결법

- `gcc`, `afl-cc`, `afl-fuzz`가 없음: 저장소 루트에서 `./setup.sh --mock`을 실행하거나 `sudo apt install gcc make clang llvm afl++ libclang-rt-dev`를 실행합니다.
- `libclang_rt.asan`을 찾지 못함: Clang과 ASan Runtime 버전이 맞지 않는 상태입니다. `sudo apt install libclang-rt-dev`를 실행한 뒤 다시 빌드합니다.
- CPU 주파수 검사 오류: WSL에서 `export AFL_SKIP_CPUFREQ=1`을 사용합니다.
- `core_pattern` 오류: 메시지를 확인한 뒤에만 `export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1`을 사용합니다. 자동 비교 스크립트는 해당 환경을 감지해 설명과 함께 적용합니다.
- 결과 폴더가 이미 존재함: 삭제하지 말고 `results/blind_2`, `results/guided_2`처럼 새 이름을 사용합니다. 자동 스크립트는 항상 새 폴더를 만듭니다.
- 60초 안에 Crash 미발견: 실행 시간을 늘리거나 여러 번 반복합니다. 미발견은 취약점이 없다는 증거가 아닙니다.
- Blind Mode가 Forkserver 오류로 멈춤: 반드시 `make blind`로 제공된 실행 파일을 만들고 `AFL_DUMB_FORKSRV=1`과 `-n`을 함께 사용합니다.
- `afl-showmap` 결과가 같아 보임: 줄 수만 보지 말고 파일 내용 또는 `sha256sum`도 비교합니다. 서로 다른 Edge인데 개수만 같을 수 있습니다.
