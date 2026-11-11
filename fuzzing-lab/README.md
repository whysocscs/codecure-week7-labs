# 7주차 Fuzzing 미션 1~2 (학생용)

WSL Ubuntu에서 실행하는 교육용 Fuzzing 실습 묶음입니다. 각 미션은 독립된 폴더에서 진행합니다.

| 미션 | 폴더 | 핵심 활동 | 권장 시간 |
|---|---|---|---|
| 1. AFL++로 Heap BOF 찾기 | `mission1_buffer_boundary/` | Coverage-guided Fuzzing, Crash 재현·최소화 | 20분 |
| 2. Coverage-guided Mutation 구현 | `mission2_coverage_guided/` | 피드백 없는 Mutation 비교, **빈 함수 채우기** | 20분 |

## 준비 사항

WSL Ubuntu에서 저장소 루트로 이동한 뒤 다음 명령을 한 번 실행하세요.

```bash
./setup.sh
```

이 명령 하나가 `gcc`, `make`, `python3`, `clang`, `llvm`, `afl++`와 PI 실습 환경을 모두 설치합니다. `afl-cc`·`afl-fuzz`·`afl-tmin`·`afl-showmap`을 확인하고 AFL++/ASan 빌드와 정상 Seed 실행까지 점검합니다. Ollama를 생략하려면 `./setup.sh --mock`을 사용해도 Fuzzing 환경은 동일하게 설치됩니다.

## 실행 순서

저장소 루트에서 각 미션 폴더의 `README.md`를 따라 하세요.

```bash
cd fuzzing-lab/mission1_buffer_boundary
make afl
```

```bash
cd fuzzing-lab/mission2_coverage_guided
python3 lab2_coverage_guided.py
```

위 `cd` 명령들은 각각 저장소 루트를 기준으로 실행하는 **서로 독립적인 예시**입니다. 실제로는 한 미션을 마치고 상위 폴더로 이동한 후 다음 미션에 진입하세요.

## 주의 사항

- 미션 2의 `coverage_guided_mutation()`은 **학생이 작성하도록 `pass`로 남겨두었습니다.** 정답 함수는 들어 있지 않습니다.
- 미션 1은 AFL++ 자체가 Coverage-guided Fuzzer이므로 Blind Fuzzing으로 설명하지 않습니다.
- 미리 준비된 Crash 입력과 수정 버전 프로그램은 학생 배포본에서 제외했습니다.
- 실습은 제공된 로컬 Target에만 수행하세요. 실행 결과는 컴퓨터 환경에 따라 달라집니다.

## 제출 또는 확인 항목

1. 미션 1: AFL++ 실행 결과, Crash 재현, 최소화 전후 크기, ASan 진단과 원인
2. 미션 2: 완성한 Python 함수와 Queue/커버리지 변화 결과
