import json
import os
import re
import threading
from pathlib import Path
from .config import ROOT

LOCK = threading.Lock()
DATA_FILE = ROOT / 'data' / 'attempts.jsonl'
# Refuse common secret forms; no detector can identify every arbitrary password.
SECRET = re.compile(r'(?i)(?:\b(?:password|passwd|비밀번호|api[_ -]?key|access[_ -]?token)\s*[:=]\s*\S+|\bsk-[A-Za-z0-9_-]{12,}|\bAKIA[A-Z0-9]{16}\b|-----BEGIN [A-Z ]*PRIVATE KEY-----)')

def contains_secret(value, key=''):
    if isinstance(value, str):
        return bool(SECRET.search(value) or (key and len(key) >= 6 and key in value))
    if isinstance(value, dict): return any(contains_secret(v, key) for v in value.values())
    if isinstance(value, list): return any(contains_secret(v, key) for v in value)
    return False

def redact(value, key=''):
    if isinstance(value, str):
        value = SECRET.sub('[민감 정보 제거됨]', value)
        return value.replace(key, '[API 키 제거됨]') if key and len(key) >= 6 else value
    if isinstance(value, dict): return {k: redact(v, key) for k,v in value.items()}
    if isinstance(value, list): return [redact(v, key) for v in value]
    return value

def save(attempt):
    DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOCK:
        fd = os.open(DATA_FILE, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
        with os.fdopen(fd, 'a', encoding='utf-8') as f: f.write(json.dumps(attempt, ensure_ascii=False) + '\n')

def all_attempts(lab_id=None):
    if not DATA_FILE.exists(): return []
    with LOCK, DATA_FILE.open(encoding='utf-8') as f:
        result = [json.loads(line) for line in f if line.strip()]
    return [a for a in reversed(result) if not lab_id or a['lab_id'] == lab_id]
