#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mission_root="$(cd -- "$script_dir/.." && pwd)"
seconds=60
repeats=1

usage() {
  printf '사용법: bash scripts/run_compare.sh [--seconds N] [--repeats N]\n'
}

while (( $# > 0 )); do
  case "$1" in
    --seconds)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      seconds="$2"
      shift 2
      ;;
    --repeats)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      repeats="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

[[ "$seconds" =~ ^[0-9]+$ ]] && (( seconds >= 1 && seconds <= 3600 )) || {
  printf '오류: --seconds는 1~3600 사이의 정수여야 합니다.\n' >&2
  exit 2
}
[[ "$repeats" =~ ^[0-9]+$ ]] && (( repeats >= 1 && repeats <= 20 )) || {
  printf '오류: --repeats는 1~20 사이의 정수여야 합니다.\n' >&2
  exit 2
}

for tool in gcc afl-cc afl-fuzz; do
  command -v "$tool" >/dev/null 2>&1 || {
    printf '오류: %s를 찾을 수 없습니다. 저장소 루트에서 ./setup.sh --mock을 실행하세요.\n' "$tool" >&2
    exit 1
  }
done

cd "$mission_root"
make blind afl

export ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0
export AFL_CRASH_EXITCODE=86
export CODECURE_ASAN_EXITCODE=86
export AFL_NO_UI=1
export AFL_DISABLE_TRIM=1
export AFL_NO_ARITH=1
export AFL_TMPDIR=/tmp

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  export AFL_SKIP_CPUFREQ=1
  printf 'WSL 환경을 감지해 AFL++의 CPU 주파수 검사를 건너뜁니다.\n'
fi

if [[ -r /proc/sys/kernel/core_pattern ]] && [[ "$(< /proc/sys/kernel/core_pattern)" == \|* ]]; then
  export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
  printf '외부 Core Dump 처리기를 감지해 교육용 실행에 필요한 AFL++ 우회 설정을 적용합니다.\n'
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
result_root="$mission_root/results/compare_${timestamp}_$$"
mkdir -p "$result_root"

stat_value() {
  local file="$1"
  shift
  local key value
  for key in "$@"; do
    value="$(awk -F: -v wanted="$key" '
      {
        name = $1
        gsub(/[[:space:]]/, "", name)
        if (name == wanted) {
          sub(/^[^:]*:[[:space:]]*/, "", $0)
          print $0
          exit
        }
      }
    ' "$file")"
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return 0
    fi
  done
  printf 'N/A'
}

first_crash_time() {
  local output_dir="$1"
  local crash_dir="$output_dir/default/crashes"
  local milliseconds
  if [[ ! -d "$crash_dir" ]]; then
    crash_dir="$output_dir/crashes"
  fi
  milliseconds="$(find "$crash_dir" -maxdepth 1 -type f -name 'id:*' -printf '%f\n' 2>/dev/null \
    | sed -n 's/.*time:\([0-9][0-9]*\).*/\1/p' \
    | sort -n \
    | head -n 1)"
  if [[ -n "$milliseconds" ]]; then
    awk -v milliseconds="$milliseconds" 'BEGIN { printf "%.3f초", milliseconds / 1000 }'
  else
    printf '미발견'
  fi
}

ensure_fuzzer_stats() {
  local output_dir="$1"
  local stats="$output_dir/default/fuzzer_stats"
  local plot_data="$output_dir/plot_data"
  local last_row

  if [[ -f "$stats" ]]; then
    printf '%s' "$stats"
    return 0
  fi
  if [[ -f "$output_dir/fuzzer_stats" ]]; then
    printf '%s' "$output_dir/fuzzer_stats"
    return 0
  fi

  # AFL++ 4.09의 -n 모드는 fuzzer_stats를 쓰지 않고 같은 값을
  # plot_data에만 남긴다. 비교 코드가 버전에 의존하지 않도록 마지막 행을
  # 표준 fuzzer_stats 형태로 변환한다.
  last_row="$(awk -F, '!/^#/ && NF >= 13 { row = $0 } END { print row }' "$plot_data" 2>/dev/null || true)"
  if [[ -n "$last_row" ]]; then
    awk -F, '
      {
        for (field = 1; field <= NF; field++) {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $field)
        }
        print "run_time        : " $1
        print "cycles_done     : " $2
        print "corpus_count    : " $4
        print "saved_crashes   : " $8
        print "saved_hangs     : " $9
        print "execs_per_sec   : " $11
        print "execs_done      : " $12
        print "edges_found     : " $13
        print "stats_source    : plot_data (AFL++ -n compatibility)"
      }
    ' <<<"$last_row" >"$output_dir/fuzzer_stats"
  else
    {
      printf 'execs_done      : N/A\n'
      printf 'saved_crashes   : 0\n'
      printf 'edges_found     : 0\n'
      printf 'stats_source    : unavailable (run was too short)\n'
    } >"$output_dir/fuzzer_stats"
  fi

  printf '%s' "$output_dir/fuzzer_stats"
}

collect_metrics() {
  local output_dir="$1"
  local mode="$2"
  local prefix="$3"
  local stats
  local execs crashes crash_status crash_time coverage

  stats="$(ensure_fuzzer_stats "$output_dir")"

  execs="$(stat_value "$stats" execs_done total_execs)"
  crashes="$(stat_value "$stats" saved_crashes unique_crashes)"
  if [[ "$crashes" =~ ^[0-9]+$ ]] && (( crashes > 0 )); then
    crash_status="성공"
    crash_time="$(first_crash_time "$output_dir")"
  else
    crash_status="미발견"
    crash_time="미발견"
  fi

  if [[ "$mode" == blind ]]; then
    coverage="사용하지 않음"
  else
    coverage="$(stat_value "$stats" edges_found bitmap_cvg)"
  fi

  printf -v "${prefix}_execs" '%s' "$execs"
  printf -v "${prefix}_crashes" '%s' "$crashes"
  printf -v "${prefix}_status" '%s' "$crash_status"
  printf -v "${prefix}_time" '%s' "$crash_time"
  printf -v "${prefix}_coverage" '%s' "$coverage"
}

blind_successes=0
guided_successes=0

for (( repeat = 1; repeat <= repeats; repeat++ )); do
  run_dir="$result_root/run_$(printf '%02d' "$repeat")"
  mkdir -p "$run_dir"

  printf '\n[%d/%d] Blind Mode를 %d초 동안 실행합니다.\n' "$repeat" "$repeats" "$seconds"
  AFL_DUMB_FORKSRV=1 afl-fuzz \
    -n \
    -D \
    -i seeds/hard \
    -x dictionary/header.dict \
    -o "$run_dir/blind" \
    -m none \
    -V "$seconds" \
    -- ./build/target_hard_blind @@ \
    >"$run_dir/blind.log" 2>&1

  printf '[%d/%d] Coverage-guided Mode를 %d초 동안 실행합니다.\n' "$repeat" "$repeats" "$seconds"
  afl-fuzz \
    -D \
    -i seeds/hard \
    -x dictionary/header.dict \
    -o "$run_dir/guided" \
    -m none \
    -V "$seconds" \
    -- ./build/target_hard_afl @@ \
    >"$run_dir/guided.log" 2>&1

  collect_metrics "$run_dir/blind" blind blind
  collect_metrics "$run_dir/guided" guided guided

  [[ "$blind_status" == 성공 ]] && (( blind_successes += 1 )) || true
  [[ "$guided_status" == 성공 ]] && (( guided_successes += 1 )) || true

  printf '\n실행 %d 비교\n' "$repeat"
  printf '| 항목 | Blind | Coverage-guided |\n'
  printf '|---|---:|---:|\n'
  printf '| 총 실행 횟수 | %s | %s |\n' "$blind_execs" "$guided_execs"
  printf '| 발견한 Crash 수 | %s | %s |\n' "$blind_crashes" "$guided_crashes"
  printf '| 첫 Crash 발견 여부 | %s | %s |\n' "$blind_status" "$guided_status"
  printf '| 첫 Crash 발견 시점 | %s | %s |\n' "$blind_time" "$guided_time"
  printf '| Coverage 정보 | %s | %s |\n' "$blind_coverage" "$guided_coverage"
done

printf '\n%d회 중 Crash 발견 횟수: Blind %d회, Coverage-guided %d회\n' \
  "$repeats" "$blind_successes" "$guided_successes"
printf '결과 폴더: %s\n' "$result_root"
printf '확률적인 실험이므로 한 번의 결과만으로 일반적인 성능 우위를 단정하지 마세요.\n'
