"""실습 2: 피드백 없는 Mutation을 Coverage-guided Mutation으로 발전시키기.

사전 확인: 먼저 피드백 없는 Mutation을 실행하고 한계를 확인하세요.
    python3 lab2_coverage_guided.py

미션 2: 아래 coverage_guided_mutation() 함수를 직접 작성하세요.
    python3 lab2_coverage_guided.py --mode guided

구현 조건:
    1. 시작 입력 "AAAA"를 Queue에 넣으세요.
    2. Queue에서 하나를 골라 mutate()로 한 글자를 변형하세요.
    3. target()으로 통과한 조건문(커버리지)을 확인하세요.
    4. 이전에 없던 커버리지를 찾은 입력만 Queue에 추가하세요.
    5. "ABCD" 경로(커버리지 4)에 도달하면 입력과 실행 횟수를 출력하세요.

주의: 실제 코드 커버리지 계측이나 메모리 오류가 아니라,
      통과한 if 단계(분기)를 커버리지로 삼는 교육용 모델이다.
"""

import argparse
import random


def target(a):
    """입력에 따라 통과한 단계의 집합을 돌려준다."""
    coverage = {0}  # 프로그램 시작

    if a[0] == "A":
        coverage.add(1)
        if a[1] == "B":
            coverage.add(2)
            if a[2] == "C":
                coverage.add(3)
                if a[3] == "D":
                    coverage.add(4)  # 목표 경로에 도달!

    return coverage


def mutate(seed, rng):
    """네 글자 중 한 글자만 무작위로 변경한다."""
    a = list(seed)
    position = rng.randrange(4)
    a[position] = rng.choice("ABCD")
    return "".join(a)


def mutation_without_feedback(runs=500, random_seed=7):
    """매번 원래 Seed에서 한 글자만 변형한다. 실행 결과를 다음 입력에 반영하지 않는다."""
    rng = random.Random(random_seed)
    seed = "AAAA"
    seen = target(seed)  # 최종 결과를 집계할 뿐, 입력 생성에 사용하지 않음

    print(f"방식: 피드백 없는 Mutation | 시작 입력: {seed}")

    for run in range(1, runs + 1):
        candidate = mutate(seed, rng)  # 항상 같은 시작 입력만 변형!
        coverage = target(candidate)
        seen |= coverage

        if run <= 5:
            print(f"[{run:03d}회] 입력: {candidate} | 통과한 단계: {sorted(coverage)}")

        if 4 in coverage:
            print(f"[{run:03d}회] 목표 경로 도달! 입력: {candidate}")
            break
    else:
        print(f"{runs}회 안에 목표 경로에 도달하지 못함")

    print(f"최종 커버리지: {len(seen)}/5 단계")


def coverage_guided_mutation(runs=500, random_seed=7):
    # 미션 2: 이 함수를 직접 완성해 보세요!
    pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="실습 2: Coverage-guided Mutation 직접 구현")
    parser.add_argument("--mode", choices=["baseline", "guided"], default="baseline")
    parser.add_argument("--runs", type=int, default=500)
    parser.add_argument("--seed", type=int, default=7, help="난수 시작값")
    args = parser.parse_args()
    if args.mode == "baseline":
        mutation_without_feedback(args.runs, args.seed)
    else:
        print("미션 2: coverage_guided_mutation()을 직접 구현해 보세요!")
        coverage_guided_mutation(args.runs, args.seed)
