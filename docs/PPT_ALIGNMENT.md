# PPT와 실습 폴더 맞추기

기준 자료는 `CodeCure_7주차_Fuzzing_PI_실습구성.pptx`입니다. 숫자는 실제 파일을 처음부터 셌을 때의 슬라이드 순서이며, PPT에 인쇄된 페이지 번호와 다를 수 있습니다. PPT 파일 자체는 수정하지 않았습니다.

| PPT 실제 슬라이드 | 현재 자료와의 차이 | 수정할 내용 |
| --- | --- | --- |
| 21–22 | 현재 실습은 Fuzzing 미션 1·2만 사용하고 AFL++를 요구하지 않습니다. | AFL++·Clang 설치 안내는 삭제하거나 이번 실습 범위 밖이라고 표시합니다. |
| 23 | 학생용 미션에는 `target_easy`만 있습니다. `target_structured`와 `_fixed` 버전은 배포하지 않습니다. | Target 목록을 `target_easy` 기준으로 변경합니다. |
| 24 | 폴더는 `fuzz_lab`이 아니라 `fuzzing-lab/mission1_buffer_boundary`입니다. `make check`와 네 실행 파일은 제공하지 않습니다. | 저장소 루트 기준으로 `cd fuzzing-lab/mission1_buffer_boundary`, `make`를 안내하고 `make check`·네 파일 설명을 제거합니다. |
| 25 | `target_easy`의 정상 입력은 실행할 수 있습니다. `target_structured`와 `seeds/afl`은 제공하지 않습니다. | 두 번째 실행 예시와 해당 거부 결과는 삭제하거나 별도의 예제로 교체합니다. |
| 26–33 | Blind Fuzzing 코드와 Target은 학생용 미션 1에 있습니다. | 저장소 루트에서 미션 1 폴더로 이동한 뒤 `make`와 기존 Fuzzer 명령을 실행합니다. |
| 34–39 | `mkdir ~/week7`, `cd fuzz_lab`은 이 저장소의 실제 배치와 다릅니다. | 한 번 clone한 저장소 안의 `fuzzing-lab/mission1_buffer_boundary`로 이동하도록 변경합니다. Fuzzer 실행과 결과 확인 명령은 그 폴더에서 실행합니다. |
| 40 | 100회 결과는 시연 환경의 관찰값입니다. | `--rng-seed 7`을 동일하게 써도 OS·컴파일러·실행 환경에 따라 진단 결과가 달라질 수 있음을 안내합니다. |
| 41–45 | 학생이 경계를 직접 찾는 미션입니다. | 안내 파일과 `mission1_generate.py`의 TODO를 사용합니다. 정답 파일은 배포하지 않습니다. |
| 54–55 | Queue를 사용하는 미션 2입니다. | `fuzzing-lab/mission2_coverage_guided`로 이동해 `lab2_coverage_guided.py`의 빈 함수를 작성하고, `--mode guided`로 실행합니다. |
| 70–74 | Direct와 Role Playing은 웹 실습 1·2입니다. | `prompt-injection-lab`을 실행하고 웹에서 진행합니다. 두 실습은 같은 Target이므로 같은 입력으로 모두 성공할 수 있습니다. |
| 75–76 | PPT의 Indirect는 실습 4로 표시되지만 웹 실습은 3번입니다. | 슬라이드의 실습 번호를 3으로 변경합니다. |

## 확인한 명령

저장소 루트에서 미션 1 시작:

```bash
cd fuzzing-lab/mission1_buffer_boundary
make
export ASAN_OPTIONS=detect_leaks=0
./build/target_easy seeds/easy/short.txt
python3 tools/fuzz.py --mode blind --target ./build/target_easy --runs 100 --rng-seed 7 --out results/blind_easy
cat results/blind_easy/report.json
./build/target_easy results/blind_easy/first_finding.bin
```

마지막 명령은 발견한 오류를 재현하므로 정상 종료가 아니라 AddressSanitizer 진단과 비정상 종료가 예상됩니다. 출력 폴더가 이미 존재하면 다른 `--out` 이름을 사용하세요.

새 터미널에서 저장소 루트로 돌아온 뒤 미션 2의 기본 동작 실행:

```bash
cd fuzzing-lab/mission2_coverage_guided
python3 lab2_coverage_guided.py
```

학생이 빈 함수를 완성한 후 `python3 lab2_coverage_guided.py --mode guided`를 실행합니다. 배포본의 미완성 함수는 정답을 포함하지 않습니다.
