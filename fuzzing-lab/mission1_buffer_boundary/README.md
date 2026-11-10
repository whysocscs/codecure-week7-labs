# Mission 1. 버퍼 오버플로의 경계선을 찾아라!

**제한 시간: 15분**

Blind Fuzzing으로 `target_easy`에서 메모리 오류를 발견했습니다. 이번에는 **어떤 크기의 입력부터 오류가 발생하는지** 찾아보세요.

## 1. 프로그램 빌드

```bash
make
export ASAN_OPTIONS=detect_leaks=0
./build/target_easy seeds/easy/short.txt
echo $?
```

`ASAN_OPTIONS=detect_leaks=0`은 일부 WSL 환경에서 메모리 누수 검사기(LeakSanitizer)가 실행되지 않는 문제를 피하기 위한 설정입니다. 이번 미션에서 필요한 AddressSanitizer의 버퍼 오버플로 탐지는 계속 활성화됩니다.

## 2. Blind Fuzzing 실행

```bash
python3 tools/fuzz.py --mode blind --target ./build/target_easy --runs 100 --rng-seed 7 --out results/blind_easy
```

`results/blind_easy/first_finding.bin`은 Fuzzer가 처음 발견한 오류 입력입니다. `report.json`에서 결과별 횟수를 확인하세요. 기존 결과 폴더가 이미 있다면 `--out results/blind_easy_2`처럼 다른 이름을 사용합니다.

## 3. 미션

`mission1_generate.py`의 TODO를 작성해서 길이가 다른 입력 파일을 만들어 보세요. 프로그램 실행 시 입력 파일 경로를 인수로 전달합니다.

```bash
python3 mission1_generate.py
./build/target_easy inputs/<직접_만든_파일명>
```

**Q1.** 테스트한 입력 길이와 정상/오류 결과를 표로 기록하세요.

**Q2.** 메모리 오류가 처음 발생하는 최소 입력 크기는 몇 바이트인가요?

**Q3.** ASan 메시지의 오류 유형과 오류가 발생한 소스 위치는 무엇인가요?

**Q4.** 이 경계보다 긴 입력에서 오류가 발생하는 이유를 메모리 할당 크기와 연결해 설명하세요.

## 힌트 (5분 간격 공개)

1. 여러 크기의 입력 파일을 만들어 테스트하고 정상/오류의 경계를 찾아보세요.
2. `src/common.h`에서 메모리를 할당하는 부분과 데이터를 복사하는 반복문의 조건을 비교해 보세요.
3. 경계 부근에서 입력 크기를 1바이트씩 변경하고 ASan의 `heap-buffer-overflow` 메시지를 확인해 보세요.

## 제출 항목

- 작성한 `mission1_generate.py`
- 입력 크기별 결과표와 Q1~Q4 답변
- 오류가 처음 발생한 입력의 실행 결과 또는 ASan 로그

이 미션에서 프로그램 수정이나 수정 전후 비교는 하지 않습니다.
