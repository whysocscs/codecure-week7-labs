"""실습 2: 피드백 없는 Mutation을 Coverage-guided Mutation으로 발전시키기.

사전 확인: 먼저 Coverage Feedback을 사용하지 않는 Random Walk를 실행하세요.
    python3 lab2_coverage_guided.py --mode baseline

미션 2: 아래 TODO 1~3을 순서대로 완성하세요.
    python3 lab2_coverage_guided.py --mode guided

구현 조건:
    1. 이번 실행에서 새로 발견한 Coverage를 구하세요.
    2. 새 Coverage를 만든 입력을 Queue에 추가하세요.
    3. 발견한 Coverage를 seen_coverage에 기록하세요.

Queue 선택, Mutation, Target 실행, 결과 출력 반복문은 제공됩니다.

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
    """직전 입력을 계속 변형하되 Coverage를 입력 선택에 사용하지 않는다."""
    rng = random.Random(random_seed)
    current = "AAAA"
    seen = target(current)
    executed = 0
    found_at = None

    print(f"방식: Blind Random Walk | 시작 입력: {current}")

    for run in range(1, runs + 1):
        current = mutate(current, rng)
        coverage = target(current)
        seen |= coverage
        executed = run

        if run <= 5:
            print(f"[{run:03d}회] 입력: {current} | 통과한 단계: {sorted(coverage)}")

        if 4 in coverage:
            found_at = run
            print(f"[{run:03d}회] 목표 경로 도달! 입력: {current}")
            break

    print(f"테스트 실행 횟수: {executed}")
    print(f"발견한 최대 Coverage 단계: {max(seen)}/4")
    print(f"목표 입력 발견 여부: {'성공' if found_at is not None else '미발견'}")
    print(f"목표 발견까지의 실행 횟수: {found_at if found_at is not None else '미발견'}")


def find_new_coverage(coverage, seen_coverage):
    """STEP 1: 이번 실행에서 처음 발견한 Coverage만 반환한다."""
    # TODO 1: coverage에는 있지만 seen_coverage에는 없는 단계를 구하세요.
    # 힌트: Python의 set은 빼기(-)로 차집합을 구할 수 있습니다.
    return set()


def save_if_interesting(candidate, coverage, queue, seen_coverage):
    """STEP 2~3: 새 Coverage를 만든 입력을 Queue와 기록에 보관한다."""
    new_coverage = find_new_coverage(coverage, seen_coverage)

    if new_coverage:
        # TODO 2: candidate를 queue 끝에 추가하세요.

        # TODO 3: coverage의 단계들을 seen_coverage에 추가하세요.
        pass

    return new_coverage


def check_learning_steps():
    """학생이 어느 단계까지 완성했는지 작은 예제로 확인한다."""
    expected_new_coverage = {2}
    actual_new_coverage = find_new_coverage({0, 1, 2}, {0, 1})
    if actual_new_coverage != expected_new_coverage:
        print("[STEP 1 미완성] find_new_coverage()에서 새 Coverage {2}를 구해 보세요.")
        return False

    test_queue = ["AAAA"]
    test_seen_coverage = {0, 1}
    save_if_interesting("ABAA", {0, 1, 2}, test_queue, test_seen_coverage)

    if test_queue != ["AAAA", "ABAA"]:
        print("[STEP 2 미완성] 새 Coverage를 만든 입력 ABAA를 Queue에 추가해 보세요.")
        return False
    if test_seen_coverage != {0, 1, 2}:
        print("[STEP 3 미완성] 발견한 Coverage를 seen_coverage에 기록해 보세요.")
        return False

    print("[준비 완료] STEP 1~3을 모두 통과했습니다. Guided 탐색을 시작합니다.")
    return True


def coverage_guided_mutation(runs=500, random_seed=7):
    """Queue에 보관한 유용한 입력을 다시 Mutation하며 탐색한다."""
    if not check_learning_steps():
        return

    rng = random.Random(random_seed)
    queue = ["AAAA"]
    seen_coverage = target(queue[0])
    executed = 0
    found_at = None

    print(f"방식: Coverage-guided Mutation | 시작 Queue: {queue}")

    for run in range(1, runs + 1):
        seed = rng.choice(queue)
        candidate = mutate(seed, rng)
        coverage = target(candidate)
        new_coverage = save_if_interesting(
            candidate, coverage, queue, seen_coverage
        )
        executed = run

        if new_coverage:
            print(
                f"[{run:03d}회] 새 Coverage {sorted(new_coverage)} 발견! "
                f"입력: {candidate} | Queue 크기: {len(queue)}"
            )

        if 4 in coverage:
            found_at = run
            print(f"[{run:03d}회] 목표 경로 도달! 입력: {candidate}")
            break

    print(f"테스트 실행 횟수: {executed}")
    print(f"발견한 최대 Coverage 단계: {max(seen_coverage)}/4")
    print(f"목표 입력 발견 여부: {'성공' if found_at is not None else '미발견'}")
    print(f"목표 발견까지의 실행 횟수: {found_at if found_at is not None else '미발견'}")
    print(f"최종 Queue 크기: {len(queue)}")
    print(f"최종 Queue: {queue}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="실습 2: Coverage-guided Mutation 직접 구현")
    parser.add_argument("--mode", choices=["baseline", "guided"], default="baseline")
    parser.add_argument("--runs", type=int, default=500)
    parser.add_argument("--seed", type=int, default=7, help="난수 시작값")
    args = parser.parse_args()
    if args.runs < 1:
        parser.error("--runs는 1 이상이어야 합니다.")
    if args.mode == "baseline":
        mutation_without_feedback(args.runs, args.seed)
    else:
        print("미션 2: Coverage 기록과 Queue 저장 STEP 1~3을 완성해 보세요!")
        coverage_guided_mutation(args.runs, args.seed)
