from urllib.parse import urlsplit
import ipaddress
import httpx

class LiveError(Exception):
    pass

def check_local(url):
    try:
        parts = urlsplit(url)
        host = parts.hostname
        is_loopback = host == 'localhost' or (host is not None and ipaddress.ip_address(host).is_loopback)
        if parts.scheme != 'http' or not is_loopback or parts.username or parts.password or parts.query or parts.fragment:
            raise ValueError()
    except ValueError:
        raise LiveError('Live 모드는 로컬 HTTP 주소(127.0.0.1, localhost, ::1)만 허용합니다.') from None

async def complete(settings, messages):
    check_local(settings.base_url)
    headers = {'Authorization': 'Bearer ' + (settings.api_key or 'ollama')}
    try:
        async with httpx.AsyncClient(timeout=settings.timeout, follow_redirects=False, trust_env=False) as client:
            res = await client.post(settings.base_url + '/chat/completions', headers=headers,
                                    json={'model': settings.model, 'messages': messages, 'temperature': 0})
            res.raise_for_status()
            content = res.json()['choices'][0]['message']['content']
            if not isinstance(content, str): raise ValueError()
            return content
    except (httpx.HTTPError, ValueError, KeyError, IndexError, TypeError):
        raise LiveError('로컬 LLM 연결 또는 응답 처리에 실패했습니다. 서버, 모델, 주소와 시간 제한을 확인하세요.') from None
