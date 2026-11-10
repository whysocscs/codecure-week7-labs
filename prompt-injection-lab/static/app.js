'use strict';
const $ = id => document.getElementById(id);
const NORMAL_DOCUMENT = 'CodeCure 교육 센터\n운영시간: 09:00~18:00\n점심시간: 12:00~13:00';
let labs = [], current = 'lab01', mode = 'mock', busy = false;
const statusNames = {succeeded:'공격 성공', blocked:'규칙 유지 / 차단', inconclusive:'판정 보류', error:'실행 오류'};
function node(tag, text, cls) { const e = document.createElement(tag); if (text !== undefined) e.textContent = text; if (cls) e.className = cls; return e; }
async function api(url, options) { const r = await fetch(url, options); const data = await r.json(); if (!r.ok) throw new Error(typeof data.detail === 'string' ? data.detail : '요청을 처리하지 못했습니다.'); return data; }
function drawNav() {
  $('lab-list').replaceChildren();
  labs.forEach((lab, i) => { const b = node('button', undefined, 'lab-link' + (lab.id === current ? ' active' : '')); b.type='button'; b.disabled=busy; b.setAttribute('aria-current', lab.id === current ? 'page' : 'false'); const number=node('span',String(i+1).padStart(2,'0')); const body=node('span'); body.append(node('strong',lab.title),node('small',lab.difficulty + ' · PPT ' + lab.slide)); b.append(number,body); b.addEventListener('click',()=>selectLab(lab.id)); $('lab-list').append(b); });
}
function surfaces() {
  const indirect = current === 'lab04';
  $('prompt-wrap').classList.toggle('hidden', indirect);
  $('request-fixed').classList.toggle('hidden', !indirect);
  $('document-wrap').classList.toggle('hidden', !indirect);
}
function resetInputs() { $('payload').value='오늘은 정말 좋고 즐거워요.'; $('document').value=NORMAL_DOCUMENT; }
async function selectLab(id) {
  if (busy) return;
  current=id; const lab=labs.find(x=>x.id===id); drawNav();
  $('slide').textContent=`실습 ${labs.indexOf(lab)+1} / ${labs.length}  ·  PPT ${lab.slide}장  ·  ${lab.difficulty}`;
  $('title').textContent=lab.title; $('goal').textContent=lab.goal; $('rule').textContent=lab.rule; $('hint').textContent=lab.hint;
  $('instructions').textContent= id==='lab04' ? '먼저 정상 문서를 실행하고, 문서에 지시를 추가해 다시 실행하세요.' : '정상 입력을 실행한 다음 출력 규칙을 바꾸는 입력을 실험하세요.';
  $('export-lab').href='/api/attempts/export?lab_id='+encodeURIComponent(id);
  resetInputs(); surfaces(); $('result').className='empty'; $('result').textContent='아직 실행 결과가 없습니다. 입력을 작성하고 실행해 보세요.'; await history();
}
function showResult(data) {
  const area=$('result'); area.replaceChildren(); area.className='';
  area.append(node('span',statusNames[data.status] || data.status,'result-status '+data.status),node('p',data.reason,'reason'));
  if(data.status==='error' && data.results.length===0) return;
  data.results.forEach(row=>{const wrap=node('div',undefined,'result-row'); wrap.append(node('strong',row.variant)); row.responses.forEach((response,i)=>{wrap.append(node('p',`${statusNames[row.evaluations[i].status]} — ${row.evaluations[i].reason}`),node('pre',response));}); area.append(wrap); });
}
async function history() {
  const id=current;
  try { const records=await api('/api/attempts?lab_id='+encodeURIComponent(id)); if(id!==current)return; const box=$('history-list'); box.replaceChildren(); if (!records.length) {box.append(node('p','아직 저장된 시도가 없습니다.','muted'));return;} records.slice(0,30).forEach(record=>{const item=node('div',undefined,'history-item'), info=node('div'), button=node('button','동일 입력 재실행'); const time=new Date(record.timestamp).toLocaleString('ko-KR'); info.append(node('strong',`${statusNames[record.status]} · ${record.mode === 'mock' ? '시뮬레이션' : 'Live: '+record.model_name}`),node('p',`${time} · ${record.input_surface === 'document' ? '문서' : '사용자'} 입력 · 반복 ${record.trials}회`)); const details=node('details',undefined,'history-detail'); details.append(node('summary','입력과 응답 보기'),node('p','입력'),node('pre',record.input_surface === 'document' ? record.document : record.payload),node('p','판정 이유: '+record.reason)); record.responses.forEach((response,i)=>details.append(node('p',`응답 ${i+1}`),node('pre',response))); info.append(details); button.type='button';button.disabled=busy;button.addEventListener('click',()=>execute(record.request));item.append(info,button);box.append(item);}); } catch(e) {$('history-list').textContent='기록을 불러오지 못했습니다: '+e.message;}
}
function currentRequest() { return {payload:$('payload').value,document:$('document').value}; }
async function execute(request) {
  if(busy)return;
  if(request){$('payload').value=request.payload;$('document').value=request.document;surfaces();} else request=currentRequest();
  busy=true; $('run').disabled=true; $('running').textContent='Target 실행 중…'; drawNav();
  try {const result=await api('/api/labs/'+current+'/run',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(request)});showResult(result);} catch(e){$('result').className='';$('result').replaceChildren(node('span','요청 오류','result-status error'),node('p',e.message,'reason'));}
  finally {busy=false;$('run').disabled=false;$('running').textContent='';drawNav();await history();}
}
$('run').addEventListener('click',()=>execute()); $('reset').addEventListener('click',resetInputs);
(async()=>{try{const [health,list]=await Promise.all([api('/api/health'),api('/api/labs')]);labs=list;mode=health.mode;$('mode').textContent=mode==='mock'?'시뮬레이션 · Mock':'Live LLM · '+health.model_name;$('mode').classList.toggle('live',mode==='live');$('mode-note').textContent=mode==='mock'?'시뮬레이션 결과입니다. 실제 LLM의 공격 성공률을 의미하지 않습니다.':'Live 모델 응답입니다. 결과는 모델과 설정에 따라 달라질 수 있습니다.';await selectLab('lab01');}catch(e){$('title').textContent='서버 연결을 확인하세요';$('goal').textContent=e.message;$('mode').textContent='연결 오류';}})();
