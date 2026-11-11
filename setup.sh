#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pi_root="$project_root/prompt-injection-lab"
mode="${1:---live}"
model_name="qwen2.5:1.5b-instruct"
venv_path="$project_root/.venv"
install_marker="$project_root/.ollama-install-incomplete"

usage() {
  printf '사용법: ./setup.sh [--live | --mock | --fuzzing | --check-fuzzing]\n'
  printf '  --live           PI 실습: Ollama와 실제 모델 준비 (기본값)\n'
  printf '  --mock           PI 실습: Ollama 없이 모의 모드 준비\n'
  printf '  --fuzzing        Fuzzing 실습: AFL++, 컴파일러, Python 설치 및 점검\n'
  printf '  --check-fuzzing  Fuzzing 도구 설치 상태와 ASan 빌드만 점검\n'
}

retry() {
  local attempt
  for attempt in 1 2 3; do
    if "$@"; then return 0; fi
    if (( attempt < 3 )); then
      printf '실패했습니다. %s초 후 다시 시도합니다 (%s/3).\n' "$((attempt * 5))" "$attempt" >&2
      sleep "$((attempt * 5))"
    fi
  done
  return 1
}

check_fuzzing_environment() (
  local tool smoke_dir source_file seed_file
  for tool in gcc make python3 clang afl-cc afl-fuzz afl-tmin afl-showmap; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      printf '필요한 명령을 찾지 못했습니다: %s\n' "$tool" >&2
      return 1
    fi
    printf '  OK: %s\n' "$tool"
  done

  source_file="$project_root/fuzzing-lab/mission1_buffer_boundary/src/target_easy.c"
  seed_file="$project_root/fuzzing-lab/mission1_buffer_boundary/seeds/easy/short.txt"
  if [[ ! -f "$source_file" || ! -f "$seed_file" ]]; then
    printf 'Fuzzing Target 또는 Seed 파일을 찾지 못했습니다. 저장소 루트에서 실행하세요.\n' >&2
    return 1
  fi

  smoke_dir="$(mktemp -d)" || return 1
  trap 'rm -r -- "$smoke_dir"' EXIT
  if ! afl-cc -std=c11 -g -O1 -fno-omit-frame-pointer -fsanitize=address \
    "$source_file" -o "$smoke_dir/target_easy"; then
    printf 'AFL++와 AddressSanitizer를 사용한 컴파일에 실패했습니다.\n' >&2
    return 1
  fi
  if ! ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0 \
    "$smoke_dir/target_easy" "$seed_file" >/dev/null; then
    printf '컴파일된 Target의 정상 입력 실행에 실패했습니다.\n' >&2
    return 1
  fi
  printf '  OK: AFL++ + ASan 컴파일 및 정상 입력 실행\n'
)

case "$mode" in
  --live|--mock|--fuzzing|--check-fuzzing) ;;
  --help|-h) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

if [[ "$(uname -s)" != Linux ]] || ! command -v apt-get >/dev/null 2>&1; then
  printf '이 자동 설치 스크립트는 Ubuntu/WSL Ubuntu에서만 지원합니다.\n' >&2
  exit 1
fi

if [[ "$mode" == --check-fuzzing ]]; then
  printf '\nFuzzing 도구 및 빌드 환경 점검\n'
  check_fuzzing_environment
  printf '\nFuzzing 환경 점검 완료.\n'
  exit 0
fi

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  apt_command=(apt-get)
else
  if ! command -v sudo >/dev/null 2>&1; then
    printf '시스템 패키지 설치에 sudo가 필요합니다.\n' >&2
    exit 1
  fi
  apt_command=(sudo apt-get)
fi

if [[ "$mode" == --fuzzing ]]; then
  printf '\n[1/2] AFL++ 및 Fuzzing 필수 패키지 설치\n'
  "${apt_command[@]}" update
  "${apt_command[@]}" install -y \
    git ca-certificates python3 build-essential clang llvm afl++

  printf '\n[2/2] Fuzzing 도구 및 빌드 환경 점검\n'
  if ! check_fuzzing_environment; then
    printf 'Fuzzing 환경 점검에 실패했습니다. 설치 로그를 확인하고 ./setup.sh --check-fuzzing을 실행하세요.\n' >&2
    exit 1
  fi
  printf '\nFuzzing 환경 준비 완료.\n'
  printf '다음 단계는 fuzzing-lab/README.md를 참고하세요.\n'
  printf '나중에 설치 상태만 확인하려면 ./setup.sh --check-fuzzing을 실행하세요.\n'
  exit 0
fi

printf '\n[1/5] Ubuntu 필수 패키지 설치\n'
"${apt_command[@]}" update
"${apt_command[@]}" install -y \
  git curl ca-certificates python3 python3-venv build-essential zstd

system_python=/usr/bin/python3
if ! "$system_python" -c 'import sys; sys.exit(sys.version_info < (3, 11))'; then
  printf 'Python 3.11 이상이 필요합니다. 현재 버전: ' >&2
  "$system_python" --version >&2
  printf 'Ubuntu 배포판을 업데이트한 뒤 다시 실행하세요.\n' >&2
  exit 1
fi

printf '\n[2/5] Python 가상환경 및 실습 패키지 설치\n'
if [[ ! -e "$venv_path" ]]; then
  if ! "$system_python" -m venv "$venv_path"; then
    printf '가상환경 생성에 실패했습니다. %s를 확인한 후 다시 실행하세요.\n' "$venv_path" >&2
    exit 1
  fi
fi
if ! "$venv_path/bin/python" -m pip --version >/dev/null 2>&1; then
  printf '가상환경이 손상되었거나 생성이 중단되었습니다. %s를 다른 이름으로 옮긴 뒤 ./setup.sh를 다시 실행하세요.\n' "$venv_path" >&2
  exit 1
fi
if ! retry "$venv_path/bin/python" -m pip install --timeout 60 -r "$pi_root/requirements.txt"; then
  printf 'Python 패키지 설치에 실패했습니다. 네트워크와 위 오류를 확인하고 ./setup.sh %s를 다시 실행하세요.\n' "$mode" >&2
  exit 1
fi

if [[ "$mode" == --live ]]; then
  printf '\n[3/5] Ollama 설치 확인\n'
  if [[ -e "$install_marker" ]] || ! command -v ollama >/dev/null 2>&1 || ! ollama --version >/dev/null 2>&1; then
    touch "$install_marker"
    installer_path="$(mktemp /tmp/codecure-ollama-install.XXXXXX.sh)"
    trap 'rm -f -- "${installer_path:-}"' EXIT
    if ! retry curl -fsSL --connect-timeout 15 --max-time 120 https://ollama.com/install.sh -o "$installer_path" || ! retry sh "$installer_path"; then
      printf 'Ollama 설치에 실패했습니다. 네트워크와 위 오류를 확인한 뒤 ./setup.sh를 다시 실행하세요.\n' >&2
      exit 1
    fi
    hash -r
    if ! command -v ollama >/dev/null 2>&1 || ! ollama --version >/dev/null 2>&1; then
      printf 'Ollama 설치 후 실행 확인에 실패했습니다. ./setup.sh를 다시 실행하세요.\n' >&2
      exit 1
    fi
    rm -f -- "$install_marker"
    rm -f -- "$installer_path"
    trap - EXIT
  else
    printf 'Ollama가 이미 설치되어 있습니다.\n'
  fi

  printf '\n[4/5] Ollama 서버 및 실습 모델 준비\n'
  if ! ollama list >/dev/null 2>&1; then
    if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
      if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        systemctl start ollama || true
      else
        sudo systemctl start ollama || true
      fi
    fi
  fi
  if ! ollama list >/dev/null 2>&1; then
    nohup ollama serve >> "$project_root/.ollama.log" 2>&1 &
  fi
  for _ in $(seq 1 30); do
    if ollama list >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  if ! ollama list >/dev/null 2>&1; then
    printf 'Ollama 서버를 시작하지 못했습니다. %s를 확인하세요.\n' "$project_root/.ollama.log" >&2
    exit 1
  fi
  if ! retry ollama pull "$model_name"; then
    printf '모델 다운로드에 실패했습니다. 네트워크와 디스크 공간을 확인하고 ./setup.sh를 다시 실행하세요.\n' >&2
    printf '모의 실습부터 진행하려면 ./setup.sh --mock을 실행하세요.\n' >&2
    exit 1
  fi
  selected_mode=live
else
  printf '\n[3/5] Ollama 설치 생략 (--mock)\n'
  printf '\n[4/5] 모델 다운로드 생략 (--mock)\n'
  selected_mode=mock
fi

printf '\n[5/5] 로컬 실행 설정 작성\n'
env_path="$pi_root/.env"
if [[ -e "$env_path" ]]; then
  env_temp="$(mktemp "$pi_root/.env.tmp.XXXXXX")"
  awk -v selected_mode="$selected_mode" '
    BEGIN { mode_written = 0 }
    /^LAB_MODE=/ {
      if (!mode_written) {
        print "LAB_MODE=" selected_mode
        mode_written = 1
      }
      next
    }
    { print }
    END {
      if (!mode_written) print "LAB_MODE=" selected_mode
    }
  ' "$env_path" > "$env_temp"
  chmod 600 "$env_temp"
  mv -f -- "$env_temp" "$env_path"
  printf '기존 .env의 다른 값은 유지하고 LAB_MODE=%s로 설정했습니다.\n' "$selected_mode"
else
  printf 'LAB_MODE=%s\nLLM_BASE_URL=http://127.0.0.1:11434/v1\nLLM_MODEL=%s\nLLM_API_KEY=\nLLM_TIMEOUT_SECONDS=180\n' \
    "$selected_mode" "$model_name" > "$env_path"
  chmod 600 "$env_path"
fi

printf '\n설정 완료 (%s 모드). 다음 명령으로 시작하세요:\n  ./start.sh\n\n' "$selected_mode"
printf '퍼징 미션은 fuzzing-lab/README.md를 확인하세요.\n'
