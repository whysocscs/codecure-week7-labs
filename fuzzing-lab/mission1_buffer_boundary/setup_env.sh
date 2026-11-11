#!/usr/bin/env bash

# This file must be sourced because exported variables need to remain in the
# student's current terminal after setup finishes.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf '이 스크립트는 현재 터미널에 환경변수를 설정해야 합니다.\n' >&2
  printf '다음처럼 실행하세요: source ./setup_env.sh\n' >&2
  exit 2
fi

mission_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for required_tool in make afl-cc afl-fuzz afl-tmin; do
  if ! command -v "$required_tool" >/dev/null 2>&1; then
    printf '오류: %s를 찾을 수 없습니다. 저장소 루트에서 ./setup.sh --mock을 먼저 실행하세요.\n' \
      "$required_tool" >&2
    unset mission_root required_tool
    return 1
  fi
done

cd "$mission_root" || return 1

printf '[1/3] Mission 1 Target을 AFL++와 ASan으로 빌드합니다.\n'
if ! make afl; then
  printf '오류: Target 빌드에 실패했습니다. 위 컴파일 오류를 확인하세요.\n' >&2
  unset mission_root required_tool
  return 1
fi

printf '\n[2/3] 현재 터미널의 Fuzzing 환경을 설정합니다.\n'
export ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0
export AFL_TMPDIR=/tmp

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  export AFL_SKIP_CPUFREQ=1
  printf '  WSL 감지: AFL_SKIP_CPUFREQ=1\n'
fi

if [[ -r /proc/sys/kernel/core_pattern ]] && \
   [[ "$(< /proc/sys/kernel/core_pattern)" == \|* ]]; then
  export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
  printf '  외부 Core Dump 처리기 감지: AFL++ 시작 검사 우회 적용\n'
fi

printf '\n[3/3] 기존 결과와 겹치지 않는 출력 경로를 준비합니다.\n'
mkdir -p results
output_base="results/afl_easy_$(date +%Y%m%d_%H%M%S)"
OUTPUT="$output_base"
output_suffix=2
while [[ -e "$OUTPUT" ]]; do
  OUTPUT="${output_base}_$output_suffix"
  ((output_suffix += 1))
done
export OUTPUT

printf '환경 준비 완료: OUTPUT=%s\n\n' "$OUTPUT"
printf '이제 학생이 직접 다음 명령으로 Fuzzing을 실행하세요.\n\n'
printf 'afl-fuzz \\\n'
printf '  -i seeds/easy \\\n'
printf '  -o "$OUTPUT" \\\n'
printf '  -m none \\\n'
printf '  -V 60 \\\n'
printf '  -- ./build/target_easy @@\n'

unset mission_root required_tool output_base output_suffix
