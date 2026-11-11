# 7주차 Fuzzing Lab: 입력을 바꾸고, 경로를 발견하고, 비교하기

이 실습은 WSL2 Ubuntu 또는 Ubuntu 22.04/24.04에서 진행합니다. 세 Mission은 순서대로 연결되지만 각 폴더에서 독립적으로 실행할 수도 있습니다.

| Mission | 핵심 활동 | 권장 시간 |
|---|---|---:|
| 1. AFL++로 Heap BOF 찾기 | 실제 Fuzzer로 Crash 발견·재현·최소화 | 20분 |
| 2. Coverage-guided Mutation 구현 | Python으로 Feedback과 Queue의 역할 구현 | 20~25분 |
| 3. Blind와 Coverage-guided 비교 | 더 어려운 Target에 두 AFL++ 모드 적용 | 20분 |

## 먼저 알아둘 용어

- **Target**: 테스트하려는 프로그램
- **Seed**: Fuzzer가 시작할 때 사용하는 입력
- **Mutation**: 기존 입력의 일부를 바꾸는 것
- **Coverage**: 프로그램에서 실행해 본 코드 경로에 관한 정보
- **Queue**: 다음 Mutation에 활용할 가치가 있는 입력을 저장하는 곳
- **Crash**: 프로그램이 비정상적으로 종료하는 현상
- **ASan(AddressSanitizer)**: 잘못된 메모리 접근을 찾아 위치와 원인을 알려 주는 도구
- **Heap Buffer Overflow(Heap BOF)**: Heap에 할당한 공간의 경계를 넘어 쓰는 오류

## 사전 준비

저장소 루트에서 기존 설치 스크립트를 실행합니다. Fuzzing만 진행하고 Ollama를 설치하지 않으려면 현재 제공되는 `--mock` 모드를 사용할 수 있습니다.

```bash
./setup.sh --mock
```

설치 여부는 다음 명령으로 확인합니다.

```bash
gcc --version
python3 --version
afl-cc --version
afl-fuzz -h
afl-tmin -h
afl-showmap -h
```

수동 설치가 필요하면 Ubuntu 터미널에서 실행합니다.

```bash
sudo apt update
sudo apt install -y gcc make clang llvm afl++ python3
```

## 권장 진행 순서

각 명령은 저장소 루트에서 시작하는 독립적인 예시입니다.

```bash
cd fuzzing-lab/mission1_buffer_boundary
source ./setup_env.sh
```

```bash
cd fuzzing-lab/mission2_coverage_guided
python3 lab2_coverage_guided.py --mode baseline --runs 500 --seed 7
```

```bash
cd fuzzing-lab/mission3_harder_target
bash scripts/run_compare.sh --seconds 60
```

Mission 1에서 실제 AFL++ 사용법을 익히고, Mission 2에서 Coverage Feedback의 원리를 작은 Python 모델로 구현합니다. Mission 3에서는 동일한 AFL++과 동일한 Seed를 사용하되 Coverage Feedback의 사용 여부만 바꾸어 관찰합니다.

## 주의 사항

- Mission 1과 3의 메모리 오류는 수업을 위해 의도적으로 남긴 취약점입니다. 제공된 로컬 Target에서만 실습하세요.
- Mission 2는 전체 함수를 비워 두지 않고, 새 Coverage 계산과 Queue/기록 갱신의 세 TODO를 단계별로 완성하도록 구성했습니다.
- Seed 폴더에는 정답 입력이나 미리 만든 Crash 입력이 없습니다.
- `build/`, `results/`, Crash와 로그는 Git에 커밋하지 않습니다.
- Fuzzing은 확률적인 탐색입니다. 한 번 실패했다고 취약점이 없다는 뜻이 아니며, 한 번의 결과만으로 두 방식의 일반적인 우위를 단정할 수도 없습니다.

각 Mission의 자세한 명령과 제출 항목은 다음 문서를 따르세요.

- [Mission 1](mission1_buffer_boundary/README.md)
- [Mission 2](mission2_coverage_guided/README.md)
- [Mission 3](mission3_harder_target/README.md)
