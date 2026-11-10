# Mission 2. Coverage-guided Mutation Fuzzer를 완성하라!

**권장 시간: 20분**

이번 미션은 `lab2_coverage_guided.py`의 비어 있는 `coverage_guided_mutation()` 함수를 직접 구현하는 것입니다.

## 1. 피드백 없는 Mutation 실행

```bash
python3 lab2_coverage_guided.py
```

기본 프로그램은 매번 시작 Seed `AAAA`의 한 글자만 변형하며, 발견한 입력을 다음 입력 생성에 활용하지 않습니다.

## 2. 학생 구현 미션

`coverage_guided_mutation()`은 현재 `pass`로 비어 있습니다. 이 함수만 직접 작성하세요.

구현 조건:

1. 시작 입력 `AAAA`를 Queue에 저장한다.
2. Queue에서 입력 하나를 선택해 `mutate()`로 변형한다.
3. `target()`으로 통과한 단계(커버리지)를 확인한다.
4. **새로운 커버리지**를 발견한 입력만 Queue에 추가한다.
5. 목표 경로 `ABCD`에 도달하면 입력과 실행 횟수를 출력한다.

## 3. 결과 비교

```bash
python3 lab2_coverage_guided.py --mode guided
```

피드백 없는 방식과 비교해 Queue와 커버리지가 어떻게 달라졌는지 설명하세요.

## 제출 항목

- 직접 작성한 `coverage_guided_mutation()` 함수
- 실행 결과
- 새로운 커버리지가 입력 선택에 도움이 되는 이유 한 문단

이 코드는 교육용으로 조건문 통과 단계를 기록하는 모델입니다.
