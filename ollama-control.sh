#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
action="${1:-restart}"
if [[ $# -gt 1 ]] || [[ "$action" != status && "$action" != start && "$action" != stop && "$action" != restart ]]; then
  printf '사용법: ./ollama-control.sh [status | start | stop | restart]\n' >&2
  exit 2
fi
if ! command -v ollama >/dev/null 2>&1; then
  printf 'Ollama를 찾을 수 없습니다. ./setup.sh를 실행하세요.\n' >&2
  exit 1
fi

# systemd가 실행 중이고 Ollama 서비스가 등록되어 있을 때만 systemctl을 사용합니다.
use_systemd=false
if command -v systemctl >/dev/null 2>&1 && \
   [[ "$(systemctl show --property=LoadState --value ollama.service 2>/dev/null || true)" == loaded ]]; then
  use_systemd=true
fi

service_command() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    systemctl "$@" ollama.service
  else
    sudo systemctl "$@" ollama.service
  fi
}

stop_server() {
  if "$use_systemd"; then
    service_command stop || return 1
  fi
  # 현재 사용자가 직접 실행한 serve 프로세스만 종료합니다.
  local -a pids=()
  mapfile -t pids < <(ps -u "$(id -u)" -o pid=,args= | awk '$2 ~ /(^|\/)ollama$/ && $3 == "serve" {print $1}')
  if (( ${#pids[@]} )); then
    kill "${pids[@]}" || return 1
    local pid attempt
    for attempt in {1..30}; do
      local running=false
      for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then running=true; fi
      done
      if ! "$running"; then break; fi
      sleep 1
    done
    if "$running"; then
      printf 'Ollama 프로세스가 종료되지 않았습니다. 직접 상태를 확인하세요.\n' >&2
      return 1
    fi
  fi
}

start_server() {
  if ollama list >/dev/null 2>&1; then
    printf 'Ollama 서버가 이미 실행 중입니다.\n'
    return 0
  fi
  if "$use_systemd"; then
    service_command start || return 1
  else
    nohup ollama serve >> "$project_root/.ollama.log" 2>&1 &
  fi
  for _ in {1..30}; do
    if ollama list >/dev/null 2>&1; then
      printf 'Ollama 서버가 실행 중입니다.\n'
      return 0
    fi
    sleep 1
  done
  printf 'Ollama 서버에 연결하지 못했습니다. %s 또는 systemctl status ollama를 확인하세요.\n' "$project_root/.ollama.log" >&2
  return 1
}

case "$action" in
  status)
    if ollama list; then
      printf '\nOllama 서버에 연결되었습니다.\n'
    else
      printf 'Ollama 서버에 연결하지 못했습니다. ./ollama-control.sh restart를 시도하세요.\n' >&2
      exit 1
    fi
    ;;
  start) start_server ;;
  stop) stop_server; printf 'Ollama 서버 종료를 요청했습니다.\n' ;;
  restart) stop_server; start_server ;;
esac
