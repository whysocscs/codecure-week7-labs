#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pi_root="$project_root/prompt-injection-lab"
mode="${1:---live}"
model_name="qwen2.5:1.5b-instruct"

if [[ "$mode" != --live && "$mode" != --mock ]]; then
  printf '사용법: ./setup.sh [--live | --mock]\n' >&2
  exit 2
fi

if [[ "$(uname -s)" != Linux ]] || ! command -v apt-get >/dev/null 2>&1; then
  printf '이 자동 설치 스크립트는 Ubuntu/WSL Ubuntu에서만 지원합니다.\n' >&2
  exit 1
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

printf '\n[1/5] Ubuntu 필수 패키지 설치\n'
"${apt_command[@]}" update
"${apt_command[@]}" install -y \
  git curl ca-certificates python3 python3-pip build-essential

system_python=/usr/bin/python3
if ! "$system_python" -c 'import sys; sys.exit(sys.version_info < (3, 11))'; then
  printf 'Python 3.11 이상이 필요합니다. 현재 버전: ' >&2
  "$system_python" --version >&2
  printf 'Ubuntu 배포판을 업데이트한 뒤 다시 실행하세요.\n' >&2
  exit 1
fi

printf '\n[2/5] Python 실습 패키지 설치 (venv 사용 안 함)\n'
pip_options=(install --user --upgrade)
pip_help="$("$system_python" -m pip install --help 2>/dev/null || true)"
if [[ "$pip_help" == *--break-system-packages* ]]; then
  pip_options+=(--break-system-packages)
fi
"$system_python" -m pip "${pip_options[@]}" -r "$pi_root/requirements.txt"

if [[ "$mode" == --live ]]; then
  printf '\n[3/5] Ollama 설치 확인\n'
  if ! command -v ollama >/dev/null 2>&1; then
    installer_path="$(mktemp /tmp/codecure-ollama-install.XXXXXX.sh)"
    trap 'rm -f -- "${installer_path:-}"' EXIT
    curl -fsSL https://ollama.com/install.sh -o "$installer_path"
    sh "$installer_path"
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
  ollama pull "$model_name"
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
