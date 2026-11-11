#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pi_root="$project_root/prompt-injection-lab"

if [[ ! -e "$pi_root/.env" ]]; then
  printf '먼저 저장소 루트에서 ./setup.sh 또는 ./setup.sh --mock을 실행하세요.\n' >&2
  exit 1
fi

python="$project_root/.venv/bin/python"
if ! "$python" -c 'import fastapi, uvicorn, httpx, dotenv' >/dev/null 2>&1; then
  printf 'Python 패키지가 준비되지 않았습니다. ./setup.sh를 다시 실행하세요.\n' >&2
  exit 1
fi

lab_mode="$(awk -F= '$1 == "LAB_MODE" { print $2; exit }' "$pi_root/.env" | tr -d '\r')"
if [[ "$lab_mode" == live ]]; then
  if ! command -v ollama >/dev/null 2>&1; then
    printf 'Live 모드에 Ollama가 필요합니다. ./setup.sh를 다시 실행하세요.\n' >&2
    exit 1
  fi
  if ! ollama list >/dev/null 2>&1; then
    nohup ollama serve >> "$project_root/.ollama.log" 2>&1 &
    for _ in $(seq 1 30); do
      if ollama list >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done
  fi
  if ! ollama list >/dev/null 2>&1; then
    printf 'Ollama 서버를 시작하지 못했습니다. ./ollama-control.sh restart를 실행하거나 %s를 확인하세요.\n' "$project_root/.ollama.log" >&2
    exit 1
  fi
fi

cd "$pi_root"
printf '\n웹 실습을 시작합니다. 브라우저에서 여세요: http://127.0.0.1:8000\n'
printf '종료하려면 Ctrl+C를 누르세요.\n\n'
exec "$python" run.py
