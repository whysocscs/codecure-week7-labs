"""미션 1: 다양한 길이의 입력 파일을 생성하는 부분을 직접 작성하세요."""

from pathlib import Path


def main():
    output_dir = Path("inputs")
    output_dir.mkdir(exist_ok=True)

    # TODO 1. 테스트할 입력 길이 여러 개를 정하세요.
    # TODO 2. 길이별로 데이터(b"A" * 길이)를 만드세요.
    # TODO 3. output_dir 안에 파일로 저장하세요.
    pass


if __name__ == "__main__":
    main()
