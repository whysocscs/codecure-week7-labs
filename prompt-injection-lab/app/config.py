import os
from pathlib import Path
from dataclasses import dataclass
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / '.env', override=False)

@dataclass(frozen=True)
class Settings:
    mode: str
    base_url: str
    model: str
    api_key: str
    timeout: float

def get_settings():
    mode = os.getenv('LAB_MODE', 'mock').strip().lower()
    if mode not in {'mock', 'live'}:
        raise ValueError('LAB_MODE는 mock 또는 live여야 합니다.')
    timeout = float(os.getenv('LLM_TIMEOUT_SECONDS', '30'))
    if not 0 < timeout <= 300:
        raise ValueError('LLM_TIMEOUT_SECONDS는 0보다 크고 300 이하여야 합니다.')
    return Settings(mode, os.getenv('LLM_BASE_URL', 'http://127.0.0.1:11434/v1').rstrip('/'),
                    os.getenv('LLM_MODEL', 'llama3.2'), os.getenv('LLM_API_KEY', ''), timeout)
