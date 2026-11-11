# CodeCure 7주차 실습

이 저장소 하나에 **Fuzzing 미션 1~2**과 **Prompt Injection 실습 1~3**이 들어 있습니다. PPT를 보면서 해당 실습을 진행하고, 자세한 미션 안내는 각 폴더의 README를 확인하세요.

| 폴더 | 실습 | 방식 |
| --- | --- | --- |
| `fuzzing-lab/` | 버퍼 경계, Coverage-guided Mutation | WSL Ubuntu 터미널 |
| `prompt-injection-lab/` | Direct PI, Role Playing, Indirect PI | 로컬 웹 브라우저 |

PPT의 기존 `fuzz_lab` 경로는 이 저장소의 폴더 구조와 다를 수 있습니다. 실제 실행은 아래 경로와 각 미션 README를 기준으로 합니다. PPT 파일은 포함하거나 수정하지 않았습니다. `make check`, `target_structured`와 수정 버전 Target도 학생용 미션에는 없습니다. 슬라이드별 교체 안내는 [PPT 대조표](docs/PPT_ALIGNMENT.md)를 확인하세요.

## 1. 준비

Windows에서는 **WSL Ubuntu** 터미널에서 진행합니다. 최초 설치에는 인터넷과 `sudo` 권한이 필요합니다. 자동 설치 스크립트는 Ubuntu/WSL Ubuntu와 Python 3.11 이상을 지원합니다.

저장소를 복제하고 폴더로 이동합니다.

```bash
git clone https://github.com/whysocscs/codecure-week7-labs.git
cd codecure-week7-labs
```

저장소 루트에서 다음 명령을 한 번 실행하면 모든 실습 환경을 준비합니다.

```bash
./setup.sh
```

`setup.sh`는 AFL++·Clang/LLVM·GCC/Make·Python·zstd를 설치하고 Fuzzing Target의 AFL++/ASan 빌드를 점검합니다. 이어서 PI 실습용 `.venv`, Ollama 서버, `qwen2.5:1.5b-instruct` 모델까지 준비합니다. 모델 파일은 약 1GB이며 실행 시 추가 메모리가 필요합니다.

설치 중 Ubuntu 패키지 변경을 위해 `sudo` 암호를 물을 수 있습니다. 기존 `prompt-injection-lab/.env`가 있으면 다른 값은 보존하고 `LAB_MODE=live`만 반영합니다. Ollama 설치 스크립트는 `https://ollama.com/install.sh`에서 내려받습니다.

설치나 모델 다운로드가 중단되면 네트워크와 디스크 여유 공간을 확인하고 `./setup.sh`를 다시 실행하세요. Python 패키지 및 Ollama 설치와 모델 다운로드는 실패 시 자동으로 최대 세 번 시도합니다. 중단된 모델 다운로드가 이어지는지는 Ollama 버전과 오류 상황에 따라 다릅니다. 가상환경이 손상되었다는 메시지가 나오면 `.venv`를 다른 이름으로 옮긴 후 다시 실행하세요. Python 3.11 미만이면 이를 제공하는 Ubuntu 버전으로 업데이트해야 합니다.

Ollama와 모델만 생략하려면 다음을 사용합니다. AFL++을 포함한 나머지 실습 환경은 동일하게 설치됩니다.

```bash
./setup.sh --mock
```

처음 설치 후 웹 앱은 인터넷 없이 실행할 수 있습니다. Mock 결과는 실제 AI의 응답이나 공격 성공률이 아닙니다. 기존 `.env`의 다른 값은 보존하고 `LAB_MODE=mock`만 반영합니다.

## 2. PI/IPI 웹 앱 시작

```bash
./start.sh
```

브라우저에서 **http://127.0.0.1:8000** 을 엽니다. 화면 상단에서 `Live LLM` 또는 `시뮬레이션 · Mock`을 확인하세요. 서버를 종료하려면 터미널에서 `Ctrl+C`를 누릅니다. Live 모드에서 모델 연결 오류가 발생하면 Mock으로 자동 전환하지 않습니다.

Live 모드에서 Ollama 연결에 문제가 생기면 다른 터미널을 열어 저장소 루트에서 다음을 실행하세요.

```bash
./ollama-control.sh status   # 연결 상태와 모델 확인
./ollama-control.sh restart  # Ollama 서버 재시작
```

`start`와 `stop`도 사용할 수 있습니다. 기본 인자 없이 실행하면 재시작합니다. systemd 서비스가 있으면 해당 서비스를 제어하고, 그렇지 않으면 현재 사용자가 직접 실행한 Ollama 서버를 제어합니다. 서비스 제어에는 `sudo` 암호가 필요할 수 있습니다. 이 스크립트는 웹 앱이 아니라 Ollama 서버를 제어합니다. 별도 `LLM_BASE_URL`을 설정했다면 해당 서버 주소도 확인하세요.

1. **Direct:** 정상 응답과 출력 형식을 바꾸려는 입력을 비교합니다.
2. **Role Playing:** 역할이나 상황을 부여한 입력과 기본 입력을 비교합니다.
3. **Indirect:** 문서 내용이 운영시간 추출 응답에 영향을 주는지 살펴봅니다.

Direct와 Role Playing은 같은 Target과 성공 기준을 사용하므로, 같은 공격문이 두 실습에서 모두 성공할 수 있습니다. Indirect의 자동 판정은 제한된 예시를 보수적으로 검사하고 모호한 결과는 판정 보류로 표시합니다. 자세한 내용은 [PI 실습 안내](prompt-injection-lab/README.md)를 참고하세요.

## 3. Fuzzing 미션 시작

**새 터미널을 열어 저장소 루트로 이동한 뒤**, 각 미션 폴더에서 진행하세요.

- [미션 1: AFL++로 Heap Buffer Overflow 찾기](fuzzing-lab/mission1_buffer_boundary/README.md)
- [미션 2: Coverage-guided Mutation 구현](fuzzing-lab/mission2_coverage_guided/README.md)

예를 들어 미션 1 시작은 다음과 같습니다.

```bash
cd fuzzing-lab/mission1_buffer_boundary
make afl
```

미션 2의 빈 함수는 학생이 직접 작성합니다. [Fuzzing 전체 안내](fuzzing-lab/README.md)를 함께 읽으세요.

## 기록과 주의사항

실습은 본인 컴퓨터의 제공된 Target에서만 진행합니다. 실제 계정, 비밀번호, 개인정보, 실제 API 키를 입력하지 마세요. AI에는 터미널이나 외부 도구 사용 권한을 주지 않습니다. 웹 앱은 `127.0.0.1`에만 열립니다.

PI 시도 기록은 `prompt-injection-lab/data/attempts.jsonl`에 남습니다. `.gitignore`는 로컬 설정, 실행 기록, 빌드 결과와 가상환경을 Git에서 제외합니다. 제거 전에는 필요한 기록을 직접 확인하세요.

테스트:

```bash
cd prompt-injection-lab
../.venv/bin/python -m pytest -q
```
