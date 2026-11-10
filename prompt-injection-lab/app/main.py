from datetime import datetime, timezone
from uuid import uuid4
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from .catalog import LABS
from .config import ROOT, get_settings
from .engine import target, judge
from .llm_client import LiveError
from .models import RunRequest
from .storage import save, all_attempts, contains_secret, redact

app = FastAPI(title='CodeCure Prompt Injection Lab', docs_url=None, redoc_url=None, openapi_url=None)

@app.middleware('http')
async def local_only(request: Request, call_next):
    host = request.headers.get('host', '').lower()
    origin = request.headers.get('origin')
    if host not in {'localhost:8000','127.0.0.1:8000','[::1]:8000','testserver'}:
        return JSONResponse({'detail':'로컬 주소로 접속하세요.'}, status_code=403)
    if origin and origin not in {'http://localhost:8000','http://127.0.0.1:8000','http://[::1]:8000','http://testserver'}:
        return JSONResponse({'detail':'외부 출처의 요청은 허용하지 않습니다.'}, status_code=403)
    response = await call_next(request)
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['Content-Security-Policy'] = "default-src 'self'; style-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'"
    return response

@app.get('/api/health')
def health():
    try:
        s = get_settings()
        return {'ok':True,'mode':s.mode,'model_name':s.model if s.mode == 'live' else None}
    except ValueError as e:
        raise HTTPException(500, str(e)) from None

@app.get('/api/labs')
def labs(): return LABS

@app.get('/api/labs/{lab_id}')
def lab(lab_id: str):
    selected = next((x for x in LABS if x['id'] == lab_id), None)
    if not selected: raise HTTPException(404, '실습을 찾을 수 없습니다.')
    return {**selected, 'input_fields':['payload','document'] if lab_id == 'lab04' else ['payload']}

@app.get('/api/attempts/export')
def export(lab_id: str | None = None):
    return JSONResponse(all_attempts(lab_id), headers={'Content-Disposition':'attachment; filename="codecure-attempts.json"'})

@app.get('/api/attempts')
def attempts(lab_id: str | None = None): return all_attempts(lab_id)

@app.post('/api/labs/{lab_id}/run')
async def run(lab_id: str, body: RunRequest):
    lab(lab_id)
    try: settings = get_settings()
    except ValueError as exc: raise HTTPException(500, str(exc)) from None
    if contains_secret(body.model_dump(), settings.api_key):
        raise HTTPException(400, 'API 키 또는 비밀번호로 보이는 입력은 저장하지 않습니다. 교육용 내용만 사용하세요.')
    scenario = 'indirect' if lab_id == 'lab04' else 'direct'
    if scenario == 'indirect' and not body.document.strip(): raise HTTPException(400, '문서 본문을 입력하세요.')
    if scenario == 'direct' and not body.payload.strip(): raise HTTPException(400, '프롬프트를 입력하세요.')
    prompt = body.payload if scenario == 'direct' else '문서에서 운영시간만 추출하세요.'
    result = {'attempt_id':str(uuid4()), 'lab_id':lab_id, 'mode':settings.mode,
              'model_name':settings.model if settings.mode == 'live' else None,
              'input_surface':'document' if scenario == 'indirect' else 'user',
              'payload':prompt, 'document':body.document if scenario == 'indirect' else None,
              'request':body.model_dump(), 'responses':[], 'success':None, 'status':'inconclusive',
              'reason':'', 'trials':1, 'timestamp':datetime.now(timezone.utc).isoformat(), 'results':[]}
    try:
        response = await target(settings, scenario, prompt, body.document, False)
        evaluation = judge(scenario, response, body.document)
        result['responses'].append(response)
        result['results'].append({'variant':'입력', 'payload':prompt,
                                  'responses':[response], 'evaluations':[evaluation]})
        result.update(evaluation)
    except LiveError as exc:
        result.update(status='error',success=None,reason=str(exc))
    result = redact(result, settings.api_key)
    save(result)
    return result

@app.get('/')
def index(): return FileResponse(ROOT / 'static' / 'index.html')
app.mount('/static', StaticFiles(directory=ROOT / 'static'), name='static')
