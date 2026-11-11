# Mission 2. Coverage-guided Mutation 직접 구현하기

권장 시간은 20~25분입니다. 이번 Mission에서는 Python으로 작은 교육용 Fuzzer 모델을 완성하며 Coverage Feedback과 Queue가 왜 필요한지 살펴봅니다.

## 1. 이번 Mission의 목표

- **Mutation**: 기존 입력 한 글자를 바꾸어 새 입력을 만드는 과정을 이해합니다.
- **Coverage Feedback**: 새 실행 경로를 발견했는지 확인하는 정보를 사용합니다.
- **Queue**: 더 깊은 경로를 발견한 입력을 보관하고 다음 Mutation의 Seed로 재사용합니다.
- 피드백을 쓰지 않는 Blind Random Walk와 Coverage-guided 방식을 같은 조건으로 비교합니다.

Target의 목표 입력은 `ABCD`입니다. 중첩 조건문을 통과할 때마다 Coverage 단계가 하나씩 늘어납니다.

```text
AAAA → ABAA → ABCA → ABCD
```

이 흐름은 설명을 위한 예시일 뿐 실제 Mutation이 반드시 이 순서로 나오지는 않습니다. 또한 이 코드는 AFL++의 실제 계측이 아니라, **통과한 `if` 단계 자체를 Coverage로 간주하는 교육용 모델**입니다.

## 2. 사전 준비

Python 3가 있는지 확인하고 폴더로 이동합니다.

```bash
python3 --version
cd fuzzing-lab/mission2_coverage_guided
```

추가 Python 패키지는 필요하지 않습니다. `lab2_coverage_guided.py`에서 다음 네 함수의 역할을 먼저 확인하세요.

- `target()`: 입력이 통과한 단계의 집합을 반환
- `mutate()`: 네 글자 중 한 글자를 무작위로 변경
- `mutation_without_feedback()`: 피드백 없는 기준선
- `coverage_guided_mutation()`: 학생이 완성할 함수

## 3. 실행 명령어

Blind 기준선을 실행합니다.

```bash
python3 lab2_coverage_guided.py --mode baseline --runs 500 --seed 7
```

기준선은 `AAAA`에서 시작해 **직전에 만든 입력**을 계속 Mutation하는 Random Walk입니다. 실행 결과의 Coverage는 통계에만 사용하며 Seed 선택이나 입력 보관에는 사용하지 않습니다. 따라서 목표 도달 가능성이 구조적으로 막혀 있지는 않지만, 좋은 중간 입력을 의도적으로 보존하지도 않습니다.

함수를 완성한 뒤 Guided 모드를 실행합니다.

```bash
python3 lab2_coverage_guided.py --mode guided --runs 500 --seed 7
```

`--runs`는 최대 실행 횟수, `--seed`는 난수 시작값입니다. 두 방식에 같은 값을 주면 비교 조건을 맞출 수 있고 같은 코드는 같은 결과를 재현합니다.

## 4. 실행하면 확인할 화면이나 결과

두 모드에서 다음 정보를 확인합니다.

- 실제 테스트 실행 횟수
- 발견한 최대 Coverage 단계(최종 단계는 4)
- 목표 입력 `ABCD` 발견 여부
- 목표 발견까지의 실행 횟수 또는 `미발견`
- Guided 모드의 최종 Queue 크기

제공된 기준선은 `--seed 7`에서 같은 결과를 반복해서 출력합니다. 난수 Seed나 실행 횟수를 바꾸면 결과가 달라질 수 있습니다. 한 번의 결과만으로 항상 어느 방식이 빠르다고 단정하면 안 됩니다.

## 5. 학생이 수행할 작업

`coverage_guided_mutation()`의 `pass`를 직접 구현합니다. 학생 배포 코드에는 정답이 들어 있지 않습니다.

구현 조건:

1. 시작 Seed `AAAA`를 Queue에 추가합니다.
2. Queue에서 Seed 하나를 선택합니다.
3. 두 방식이 공통으로 쓰는 `mutate()`로 입력 하나를 변형합니다.
4. `target()`으로 Coverage를 확인합니다.
5. 이전에 없던 Coverage 단계를 발견하면 그 입력을 Queue에 추가합니다.
6. `ABCD`, 즉 Coverage 4에 도달하면 실행 횟수를 출력하고 종료합니다.
7. 종료할 때 실행 횟수, 최대 Coverage, 발견 여부, 발견 시점, Queue 크기를 출력합니다.

힌트: 난수 생성기는 함수 인자로 받은 `random_seed`로 별도로 만들 수 있습니다. “지금까지 본 Coverage”와 “다음에 선택할 입력 목록”은 서로 다른 변수로 관리해 보세요. Queue의 어느 Seed를 고를지는 직접 결정하되 Coverage를 발견하지 못한 입력을 무조건 추가하지 마세요.

## 6. 생각해 볼 질문

1. Blind Random Walk도 원리적으로 `ABCD`에 도달할 수 있는 이유는 무엇인가요?
2. 중간 입력 `ABAA` 또는 `ABCA`를 Queue에 남기면 어떤 이점이 있나요?
3. 새 Coverage가 없는 모든 입력을 Queue에 넣으면 어떤 문제가 생길까요?
4. 같은 `--seed`가 재현 가능한 비교에 도움이 되는 이유는 무엇인가요?
5. 이 교육용 Coverage와 AFL++의 실제 Coverage 계측은 무엇이 다른가요?

## 7. 제출 항목

- 직접 완성한 `coverage_guided_mutation()` 함수
- 같은 `--runs`, `--seed`로 실행한 Baseline과 Guided 결과
- 두 방식의 최대 Coverage, 발견 시점, Guided Queue 크기 비교
- Coverage Feedback이 다음 입력 선택에 도움이 되는 이유 설명

## 8. 자주 발생하는 오류와 해결법

- `IndexError`: Target에는 정확히 네 글자인 문자열이 들어가야 합니다. `mutate()`가 반환한 값을 사용했는지 확인합니다.
- Guided 모드가 아무 출력 없이 끝남: `coverage_guided_mutation()`이 아직 `pass`인지 확인합니다.
- 실행할 때마다 결과가 다름: 전역 `random` 대신 전달받은 `random_seed`로 만든 난수 생성기를 일관되게 사용했는지 확인합니다.
- Queue가 지나치게 커짐: 새 Coverage인지 확인하기 전에 모든 입력을 추가하고 있지 않은지 확인합니다.
- 목표를 못 찾음: 이것만으로 구현 오류라고 단정할 수 없습니다. 먼저 실행 횟수를 늘리고 여러 Seed로 시험한 뒤, 새 Coverage 입력이 Queue에 들어가는지 출력해 확인합니다.
