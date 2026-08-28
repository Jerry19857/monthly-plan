const WEBAPP_URL = 'https://script.google.com/macros/s/AKfycbwIFRJnRQPKI1d2bvtHm3nrWN0Dhw7sC331eTrQo5HvROiCLuxS7QPQvXAdZwj7mMstBw/exec';
const SESSION_KEY = 'mp_session';

const MONTHS_TH = ['มกราคม','กุมภาพันธ์','มีนาคม','เมษายน','พฤษภาคม','มิถุนายน',
                   'กรกฎาคม','สิงหาคม','กันยายน','ตุลาคม','พฤศจิกายน','ธันวาคม'];
let currentYear = new Date().getFullYear();
let currentMonth = new Date().getMonth();
let plans = {}, profile = { dailyWage: 0, taxRate: 0 };
let incomeMode = 'manual', clipboard = null;
let pasteTargetYear = currentYear, pasteTargetMonth = currentMonth;
let saveTimer = null;

function monthKey(y, m) { return MONTHS_TH[m]; }
function currentKey() { return monthKey(currentYear, currentMonth); }
function prevKey() { let m=currentMonth-1,y=currentYear; if(m<0){m=11;y--;} return monthKey(y,m); }
function getMonthData(k) { if(!plans[k])plans[k]={incomes:[],expenses:[]}; return plans[k]; }
function fmt(n) { return '฿'+Number(n||0).toLocaleString('th-TH',{minimumFractionDigits:0,maximumFractionDigits:2}); }
function uid() { return Date.now().toString(36)+Math.random().toString(36).slice(2,6); }
function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

// ── Toast ──
function showToast(msg,dur=2000){const t=document.getElementById('toast');t.textContent=msg;t.classList.add('show');setTimeout(()=>t.classList.remove('show'),dur);}

// ── Sync ──
function setSyncStatus(state,label){document.getElementById('syncDot').className='sync-dot '+state;document.getElementById('syncLabel').textContent=label;}

// ── API ──
function getToken() { return sessionStorage.getItem(SESSION_KEY); }

async function writeSheet(sheetName, rows) {
  const res = await fetch(WEBAPP_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'text/plain' },
    body: JSON.stringify({ sheet: sheetName, rows, token: getToken() })
  });
  const data = await res.json();
  if (data.ok === false && data.error === 'unauthorized') { lockApp(); throw new Error('unauthorized'); }
  if (!data.ok) throw new Error('write failed');
}
async function readSheet(sheetName) {
  try {
    const res = await fetch(`${WEBAPP_URL}?sheet=${encodeURIComponent(sheetName)}&token=${encodeURIComponent(getToken()||'')}`);
    const data = await res.json();
    if (data.ok === false && data.error === 'unauthorized') { lockApp(); return null; }
    return data.values || [];
  } catch { return null; }
}

// ── PIN ──
let pinInput = '';
const PIN_LENGTH = 6;

function buildNumpad() {
  const pad = document.getElementById('pinNumpad');
  const keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
  pad.innerHTML = keys.map(k => {
    if (k === '') return `<button class="pin-key empty" disabled></button>`;
    if (k === '⌫') return `<button class="pin-key del" data-key="del">⌫</button>`;
    return `<button class="pin-key" data-key="${k}">${k}</button>`;
  }).join('');
  pad.querySelectorAll('.pin-key[data-key]').forEach(btn => {
    btn.addEventListener('click', () => handlePinKey(btn.dataset.key));
  });
}

function updatePinDots() {
  document.querySelectorAll('.pin-dot').forEach((d,i) => {
    d.classList.toggle('filled', i < pinInput.length);
  });
}

async function handlePinKey(key) {
  if (key === 'del') {
    pinInput = pinInput.slice(0, -1);
    updatePinDots();
    document.getElementById('pinError').textContent = '';
    return;
  }
  if (pinInput.length >= PIN_LENGTH) return;
  pinInput += key;
  updatePinDots();
  if (pinInput.length === PIN_LENGTH) {
    await verifyPin(pinInput);
  }
}

async function verifyPin(pin) {
  const loading = document.getElementById('pinLoading');
  const errEl = document.getElementById('pinError');
  loading.textContent = 'กำลังตรวจสอบ...';
  errEl.textContent = '';
  try {
    const res = await fetch(`${WEBAPP_URL}?action=checkpin&pin=${encodeURIComponent(pin)}`);
    const data = await res.json();
    loading.textContent = '';
    if (data.ok) {
      sessionStorage.setItem(SESSION_KEY, data.token);
      showMainApp();
    } else {
      pinInput = '';
      updatePinDots();
      errEl.textContent = '❌ PIN ไม่ถูกต้อง';
      setTimeout(() => { errEl.textContent = ''; }, 2000);
    }
  } catch {
    loading.textContent = '';
    pinInput = '';
    updatePinDots();
    errEl.textContent = '⚠️ เชื่อมต่อไม่ได้ ลองใหม่';
  }
}

function showMainApp() {
  document.getElementById('pinScreen').style.display = 'none';
  document.getElementById('mainApp').style.display = 'block';
  initApp();
}

function lockApp() {
  sessionStorage.removeItem(SESSION_KEY);
  document.getElementById('mainApp').style.display = 'none';
  document.getElementById('pinScreen').style.display = 'flex';
  pinInput = '';
  updatePinDots();
  document.getElementById('pinError').textContent = '';
}

document.getElementById('logoutBtn').onclick = lockApp;

// ── Save/Load ──
async function saveMonthToSheets(key) {
  setSyncStatus('busy','กำลังบันทึก...');
  try {
    const d = getMonthData(key);
    const rows = [['type','id','name','amount','done','dueDay']];
    for (const x of d.incomes) rows.push(['income',x.id,x.name,x.amount,x.done?'1':'0','']);
    for (const x of d.expenses) rows.push(['expense',x.id,x.name,x.amount,x.done?'1':'0',x.dueDay||'']);
    await writeSheet(key, rows);
    setSyncStatus('ok','บันทึกแล้ว');
  } catch {
    setSyncStatus('err','บันทึกไม่สำเร็จ');
    showToast('❌ บันทึกไม่สำเร็จ');
  }
}
async function saveProfileToSheets() {
  try { await writeSheet('ตั้งค่า',[['dailyWage','taxRate','pin'],[(profile.dailyWage||0),(profile.taxRate||0),'']]);} catch{}
}
async function loadMonthFromSheets(key) {
  const rows = await readSheet(key);
  if (!rows||rows.length<2){plans[key]={incomes:[],expenses:[]};return;}
  const incomes=[],expenses=[];
  for(let i=1;i<rows.length;i++){
    const [type,id,name,amount,done,dueDay]=rows[i];
    if(!type)continue;
    const item={id:id||uid(),name:name||'',amount:+amount||0,done:done==='1'};
    if(type==='income')incomes.push(item);
    else if(type==='expense')expenses.push({...item,dueDay:dueDay?+dueDay:null});
  }
  plans[key]={incomes,expenses};
}
async function loadProfileFromSheets() {
  const rows = await readSheet('ตั้งค่า');
  if(rows&&rows.length>=2){profile.dailyWage=+rows[1][0]||0;profile.taxRate=+rows[1][1]||0;}
}
function scheduleSave(key){clearTimeout(saveTimer);saveTimer=setTimeout(()=>saveMonthToSheets(key),800);}

// ── Summary ──
function updateSummary(){
  const d=getMonthData(currentKey());
  const ti=d.incomes.reduce((s,x)=>s+(+x.amount||0),0);
  const ri=d.incomes.filter(x=>x.done).reduce((s,x)=>s+(+x.amount||0),0);
  const te=d.expenses.reduce((s,x)=>s+(+x.amount||0),0);
  const pe=d.expenses.filter(x=>x.done).reduce((s,x)=>s+(+x.amount||0),0);
  const bal=ti-te;
  document.getElementById('sumIncome').textContent=fmt(ti);
  document.getElementById('sumIncomeReceived').textContent='ได้รับแล้ว '+fmt(ri);
  document.getElementById('sumExpense').textContent=fmt(te);
  document.getElementById('sumExpensePaid').textContent='จ่ายแล้ว '+fmt(pe);
  const bv=document.getElementById('balanceValue'),bb=document.getElementById('balanceBadge');
  bv.textContent=fmt(bal);
  if(te-pe<=0&&te>0){bv.style.color='var(--green)';bb.className='badge badge-ok';bb.textContent='✓ จ่ายครบแล้ว';}
  else if(te-pe>0){bv.style.color=bal>=0?'var(--yellow)':'var(--red)';bb.className='badge badge-warn';bb.textContent=`ค้างจ่าย ${fmt(te-pe)}`;}
  else{bv.style.color='var(--subtext1)';bb.className='badge';bb.textContent='—';}
  const pk=prevKey(),pd=plans[pk];
  const isEmpty=d.incomes.length===0&&d.expenses.length===0;
  const hasPrev=pd&&(pd.incomes.length>0||pd.expenses.length>0);
  document.getElementById('copyBanner').style.display=(isEmpty&&hasPrev)?'block':'none';
}

// ── Render ──
const chk=c=>`<svg width="10" height="8" viewBox="0 0 10 8" fill="none"><polyline points="1,4 4,7 9,1" stroke="${c}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
function renderIncomes(){
  const d=getMonthData(currentKey()),list=document.getElementById('incomeList');
  if(!d.incomes.length){list.innerHTML='<div class="empty-state">ยังไม่มีรายการรายได้</div>';return;}
  list.innerHTML=d.incomes.map((x,i)=>`<div class="item ${x.done?'done':''}">
    <button class="item-check ${x.done?'checked-green':''}" data-action="check" data-type="income" data-i="${i}">${chk('var(--green)')}</button>
    <span class="item-name">${escHtml(x.name)}</span>
    <span class="item-amount" style="color:var(--green)">${fmt(x.amount)}</span>
    <div class="item-actions">
      <button class="item-btn edit" data-action="edit" data-type="income" data-i="${i}">✎</button>
      <button class="item-btn delete" data-action="delete" data-type="income" data-i="${i}">✕</button>
    </div></div>`).join('');
}
function renderExpenses(){
  const d=getMonthData(currentKey());
  const sorted=[...d.expenses].map((x,i)=>({...x,_i:i})).sort((a,b)=>{
    if(!a.dueDay&&!b.dueDay)return 0;if(!a.dueDay)return 1;if(!b.dueDay)return -1;return(+a.dueDay)-(+b.dueDay);
  });
  const list=document.getElementById('expenseList');
  if(!sorted.length){list.innerHTML='<div class="empty-state">ยังไม่มีรายการรายจ่าย</div>';return;}
  list.innerHTML=sorted.map(x=>`<div class="item ${x.done?'done':''}">
    <button class="item-check ${x.done?'checked-mauve':''}" data-action="check" data-type="expense" data-i="${x._i}">${chk('var(--mauve)')}</button>
    ${x.dueDay?`<span class="item-due">วัน ${x.dueDay}</span>`:''}
    <span class="item-name">${escHtml(x.name)}</span>
    <span class="item-amount" style="color:var(--maroon)">${fmt(x.amount)}</span>
    <div class="item-actions">
      <button class="item-btn edit" data-action="edit" data-type="expense" data-i="${x._i}">✎</button>
      <button class="item-btn delete" data-action="delete" data-type="expense" data-i="${x._i}">✕</button>
    </div></div>`).join('');
}
function renderAll(){
  document.getElementById('monthLabel').textContent=`${MONTHS_TH[currentMonth]} ${currentYear+543}`;
  updateSummary();renderIncomes();renderExpenses();updateProfileUI();
}
function updateProfileUI(){
  document.getElementById('dailyWage').value=profile.dailyWage||'';
  document.getElementById('taxRate').value=profile.taxRate||'';
  if(profile.dailyWage)document.getElementById('profileStatus').textContent=`ค่าแรงต่อวัน: ${fmt(profile.dailyWage)} | ภาษี: ${profile.taxRate||0}%`;
}

// ── Inline edit ──
function openEdit(type,idx){
  const d=getMonthData(currentKey()),arr=type==='income'?d.incomes:d.expenses,x=arr[idx];
  const listEl=document.getElementById(type==='income'?'incomeList':'expenseList');
  let targetEl=null;
  listEl.querySelectorAll('.item').forEach(el=>{if(el.querySelector(`[data-action="edit"][data-i="${idx}"]`))targetEl=el;});
  if(!targetEl)return;
  const nameSpan=targetEl.querySelector('.item-name'),amountSpan=targetEl.querySelector('.item-amount');
  const actions=targetEl.querySelector('.item-actions'),dueSpan=targetEl.querySelector('.item-due');
  const ni=Object.assign(document.createElement('input'),{type:'text',value:x.name,style:'flex:2'});
  const ai=Object.assign(document.createElement('input'),{type:'number',value:x.amount,style:'flex:1;min-width:80px'});
  let di=null;
  if(type==='expense'){di=Object.assign(document.createElement('input'),{type:'number',value:x.dueDay||'',placeholder:'วัน',style:'width:52px;flex-shrink:0'});if(dueSpan)dueSpan.replaceWith(di);else targetEl.insertBefore(di,nameSpan);}
  nameSpan.replaceWith(ni);amountSpan.replaceWith(ai);ni.focus();ni.select();
  const sb=Object.assign(document.createElement('button'),{className:'item-btn',textContent:'✓',style:'color:var(--green)'});
  const cb=Object.assign(document.createElement('button'),{className:'item-btn',textContent:'✕',style:'color:var(--overlay0)'});
  actions.innerHTML='';actions.appendChild(sb);actions.appendChild(cb);
  async function doSave(){const n=ni.value.trim(),a=+ai.value;if(!n||!a)return;arr[idx].name=n;arr[idx].amount=a;if(type==='expense'&&di)arr[idx].dueDay=di.value?+di.value:null;renderAll();scheduleSave(currentKey());}
  sb.onclick=doSave;cb.onclick=()=>renderAll();
  [ni,ai].forEach(inp=>inp.addEventListener('keydown',e=>{if(e.key==='Enter')doSave();if(e.key==='Escape')renderAll();}));
}

// ── Item events ──
function handleItemClick(e){
  const btn=e.target.closest('[data-action]');if(!btn)return;
  const {action,type,i:iStr}=btn.dataset,i=+iStr,d=getMonthData(currentKey());
  if(action==='check'){if(type==='income')d.incomes[i].done=!d.incomes[i].done;else d.expenses[i].done=!d.expenses[i].done;renderAll();scheduleSave(currentKey());}
  else if(action==='delete'){if(type==='income')d.incomes.splice(i,1);else d.expenses.splice(i,1);renderAll();scheduleSave(currentKey());}
  else if(action==='edit')openEdit(type,i);
}
document.getElementById('incomeList').addEventListener('click',handleItemClick);
document.getElementById('expenseList').addEventListener('click',handleItemClick);

// ── Month nav ──
async function goMonth(dy){
  currentMonth+=dy;
  if(currentMonth<0){currentMonth=11;currentYear--;}
  if(currentMonth>11){currentMonth=0;currentYear++;}
  setSyncStatus('busy','กำลังโหลด...');
  await loadMonthFromSheets(currentKey());
  setSyncStatus('ok','โหลดแล้ว');
  renderAll();
}
document.getElementById('prevMonthBtn').onclick=()=>goMonth(-1);
document.getElementById('nextMonthBtn').onclick=()=>goMonth(1);

// ── Settings ──
document.getElementById('settingsToggle').onclick=()=>{const b=document.getElementById('settingsBody'),c=document.getElementById('settingsChevron');b.classList.toggle('open');c.textContent=b.classList.contains('open')?'▴':'▾';};
document.getElementById('saveProfileBtn').onclick=async()=>{
  profile.dailyWage=+document.getElementById('dailyWage').value||0;
  profile.taxRate=+document.getElementById('taxRate').value||0;
  await saveProfileToSheets();
  document.getElementById('profileStatus').textContent=`✓ บันทึกแล้ว — ค่าแรง ${fmt(profile.dailyWage)} / ภาษี ${profile.taxRate}%`;
  setTimeout(()=>updateProfileUI(),2000);
};

// ── Mode tabs ──
document.querySelectorAll('.mode-tab').forEach(btn=>{btn.onclick=()=>{document.querySelectorAll('.mode-tab').forEach(b=>b.classList.remove('active'));btn.classList.add('active');incomeMode=btn.dataset.mode;document.getElementById('modeManual').style.display=incomeMode==='manual'?'flex':'none';document.getElementById('modeCalc').style.display=incomeMode==='calc'?'flex':'none';};});
document.getElementById('modeManual').style.display='flex';
document.getElementById('workDays').oninput=()=>{const days=+document.getElementById('workDays').value||0,box=document.getElementById('calcPreview');if(!days||!profile.dailyWage){box.classList.remove('show');return;}const gross=days*profile.dailyWage,tax=gross*(profile.taxRate/100),net=gross-tax;box.classList.add('show');box.textContent=`${days} วัน × ${fmt(profile.dailyWage)} − ภาษี ${profile.taxRate||0}% (${fmt(tax)}) = ${fmt(net)}`;};

// ── Add items ──
document.getElementById('addIncomeManualBtn').onclick=async()=>{const n=document.getElementById('incomeNameManual').value.trim(),a=+document.getElementById('incomeAmountManual').value;if(!n||!a)return;getMonthData(currentKey()).incomes.push({id:uid(),name:n,amount:a,done:false});document.getElementById('incomeNameManual').value='';document.getElementById('incomeAmountManual').value='';renderAll();scheduleSave(currentKey());};
document.getElementById('addIncomeCalcBtn').onclick=async()=>{const n=document.getElementById('incomeNameCalc').value.trim(),days=+document.getElementById('workDays').value||0;if(!n||!days||!profile.dailyWage){if(!profile.dailyWage){document.getElementById('settingsBody').classList.add('open');document.getElementById('settingsChevron').textContent='▴';}return;}const gross=days*profile.dailyWage,net=gross-gross*(profile.taxRate/100);getMonthData(currentKey()).incomes.push({id:uid(),name:n,amount:net,done:false});document.getElementById('incomeNameCalc').value='';document.getElementById('workDays').value='';document.getElementById('calcPreview').classList.remove('show');renderAll();scheduleSave(currentKey());};
document.getElementById('addExpenseBtn').onclick=async()=>{const n=document.getElementById('expenseName').value.trim(),a=+document.getElementById('expenseAmount').value,dd=document.getElementById('expenseDueDay').value;if(!n||!a)return;getMonthData(currentKey()).expenses.push({id:uid(),name:n,amount:a,dueDay:dd?+dd:null,done:false});document.getElementById('expenseName').value='';document.getElementById('expenseAmount').value='';document.getElementById('expenseDueDay').value='';renderAll();scheduleSave(currentKey());};
document.getElementById('copyFromPrevBtn').onclick=async()=>{const pk=prevKey(),pd=plans[pk];if(!pd)return;const cur=getMonthData(currentKey());cur.incomes=pd.incomes.map(x=>({...x,id:uid(),done:false}));cur.expenses=pd.expenses.map(x=>({...x,id:uid(),done:false}));renderAll();scheduleSave(currentKey());};

// ── Paste modal ──
function openPasteModal(type){const d=getMonthData(currentKey()),items=type==='income'?d.incomes:d.expenses,label=type==='income'?'รายได้':'รายจ่าย';if(!items.length){showToast(`ไม่มี${label}ในเดือนนี้`);return;}clipboard={type,items:JSON.parse(JSON.stringify(items)),label};let ty=currentYear,tm=currentMonth+1;if(tm>11){tm=0;ty++;}pasteTargetYear=ty;pasteTargetMonth=tm;document.getElementById('pasteModalTitle').textContent=`วาง${label}ไปยังเดือน`;document.getElementById('pasteModalDesc').textContent=`${items.length} รายการจาก ${MONTHS_TH[currentMonth]} ${currentYear+543}`;renderPasteGrid();document.getElementById('pasteModal').classList.add('open');}
function renderPasteGrid(){document.getElementById('pasteYearLabel').textContent=`${pasteTargetYear+543}`;const grid=document.getElementById('pasteMonthGrid');grid.innerHTML=MONTHS_TH.map((m,i)=>`<button class="month-opt ${i===pasteTargetMonth?'selected':''}" data-m="${i}">${m.slice(0,3)}</button>`).join('');grid.querySelectorAll('.month-opt').forEach(btn=>{btn.onclick=()=>{pasteTargetMonth=+btn.dataset.m;renderPasteGrid();};});}
function closePasteModal(){document.getElementById('pasteModal').classList.remove('open');clipboard=null;}
document.getElementById('pasteYearPrev').onclick=()=>{pasteTargetYear--;renderPasteGrid();};
document.getElementById('pasteYearNext').onclick=()=>{pasteTargetYear++;renderPasteGrid();};
document.getElementById('pasteModalCancel').onclick=closePasteModal;
document.getElementById('pasteModal').addEventListener('click',e=>{if(e.target===document.getElementById('pasteModal'))closePasteModal();});
document.getElementById('pasteModalConfirm').onclick=async()=>{if(!clipboard)return;const tk=monthKey(pasteTargetYear,pasteTargetMonth);await loadMonthFromSheets(tk);const target=getMonthData(tk);const newItems=clipboard.items.map(x=>({...x,id:uid(),done:false}));if(clipboard.type==='income')target.incomes=[...target.incomes,...newItems];else target.expenses=[...target.expenses,...newItems];await saveMonthToSheets(tk);closePasteModal();currentYear=pasteTargetYear;currentMonth=pasteTargetMonth;renderAll();showToast(`✓ วางรายการไปยัง ${MONTHS_TH[pasteTargetMonth]} ${pasteTargetYear+543} แล้ว`);};
document.getElementById('copyIncomeBtn').onclick=()=>openPasteModal('income');
document.getElementById('copyExpenseBtn').onclick=()=>openPasteModal('expense');

['incomeNameManual','incomeAmountManual'].forEach(id=>document.getElementById(id).addEventListener('keydown',e=>{if(e.key==='Enter')document.getElementById('addIncomeManualBtn').click();}));
['incomeNameCalc','workDays'].forEach(id=>document.getElementById(id).addEventListener('keydown',e=>{if(e.key==='Enter')document.getElementById('addIncomeCalcBtn').click();}));
['expenseName','expenseAmount','expenseDueDay'].forEach(id=>document.getElementById(id).addEventListener('keydown',e=>{if(e.key==='Enter')document.getElementById('addExpenseBtn').click();}));

// ── Init app (after PIN) ──
async function initApp(){
  setSyncStatus('busy','กำลังโหลด...');
  await Promise.all([loadMonthFromSheets(currentKey()),loadProfileFromSheets()]);
  setSyncStatus('ok','พร้อมใช้งาน');
  renderAll();
}

// ── Boot ──
buildNumpad();
if(sessionStorage.getItem(SESSION_KEY)==='1'){showMainApp();}
