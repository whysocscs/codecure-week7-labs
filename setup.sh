#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pi_root="$project_root/prompt-injection-lab"
mode="${1:---live}"
if [[ "$mode" != --live && "$mode" != --mock ]]; then
  printf '사용법: ./setup.sh [--live | --mock]\n' >&2
  exit 2
fi
if ! command -v python3 >/dev/null; then
  printf 'Python 3.11 이상을 설치하세요.\n' >&2; exit 1
fi
if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))'; then
  printf 'Python 3.11 이상이 필요합니다.\n' >&2; exit 1
fi
if [[ "$mode" == --live ]]; then
  if ! command -v ollama >/dev/null; then
    printf 'Ollama가 필요합니다. WSL Ubuntu에 설치하거나 ./setup.sh --mock을 실행하세요.\n' >&2; exit 1
  fi
  if ! ollama list >/dev/null 2>&1; then
    printf 'Ollama 서버에 연결할 수 없습니다. 서버 실행 후 다시 시도하세요.\n' >&2; exit 1
  fi
fi
printf '\n[1/3] Python 가상환경 준비\n'
python3 -m venv "$pi_root/.venv"
"$pi_root/.venv/bin/python" -m pip install -r "$pi_root/requirements.txt"
if [[ "$mode" == --live ]]; then
  printf '\n[2/3] Qwen 모델 준비 (첫 실행 시 다운로드)\n'
  ollama pull qwen2.5:1.5b-instruct
  selected_mode=live
else
  printf '\n[2/3] 시뮬레이션 모드 선택\n'
  selected_mode=mock
fi
printf '\n[3/3] 로컬 설정 확인\n'
if [[ -e "$pi_root/.env" ]]; then
  printf '기존 prompt-injection-lab/.env를 유지합니다. 선택한 모드는 기존 설정에 자동 반영되지 않습니다.\n'
else
  (set -o noclobber; printf 'LAB_MODE=%s\nLLM_BASE_URL=http://127.0.0.1:11434/v1\nLLM_MODEL=qwen2.5:1.5b-instruct\nLLM_API_KEY=\nLLM_TIMEOUT_SECONDS=180\n' "$selected_mode" > "$pi_root/.env")
  printf '실행 모드: %s\n' "$selected_mode"
fi
printf '\n설정 완료. 웹 앱 시작:\n  cd "%s"\n  .venv/bin/python run.py\n\n' "$pi_root"
printf '퍼징 미션은 fuzzing-lab/README.md를 확인하세요.\n'
