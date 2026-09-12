/* ===== module: student (teacher's view of one student, from t/student.html) ===== */
(() => {
const ON = (t, f) => on('student', t, f), DON = (t, f) => ondoc('student', t, f);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
const andList=a=>a.length<2?a.join(''):a.slice(0,-1).join(', ')+' i '+a[a.length-1];
/*SHARED*/
Object.assign(IC,{minus:'<path d="M5 12h14"/>',x:'<path d="M6 6l12 12M18 6L6 18"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',edit:'<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13 7l4 4"/>',coins:'<path d="M4 7c0-1.7 3.6-3 8-3s8 1.3 8 3-3.6 3-8 3-8-1.3-8-3z"/><path d="M4 7v5c0 1.7 3.6 3 8 3s8-1.3 8-3V7M4 12v5c0 1.7 3.6 3 8 3s8-1.3 8-3v-5"/>',trash:'<path d="M4 6h16M9 6V3h6v3M6 6l1 15h10l1-15"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const glyph=n=>`<svg class="gph" viewBox="0 0 64 64" aria-hidden="true">${GL[n]||''}</svg>`;
const mini=(cls,g)=>`<span class="card ${cls} mc"><span class="card-f"><span class="card-i">${glyph(g)}</span></span></span>`;
const bar=(v,m)=>`<div class="bar"><i style="--p:${Math.round(Math.min(v,m)/m*100)}%"></i></div>`;
const cur=n=>curN(n);
const RAB="url('__RABBITS__')";
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',tab:'badges',filter:'all',modal:null,
 get st(){return DB.sel();},get hist(){return DB.sel().hist;}};
const TL={earn:'Nagroda',spend:'Zakup',corr:'Korekta'};
/* ---------- sheet + tabs ---------- */
function sheet(){const s=S.st,ri=rankIdx(s.tot),r=RANKS[ri],nx=RANKS[ri+1];
 return `<section class="panel sheet"><div class="sh-top">${avatar(s.name)}<div><p class="crumbs"><a href="#/t/students" data-act="nav" data-to="t/students">Studenci</a>${icon('chevRight')}<span>${esc(s.name)}</span></p><h1>${esc(s.name)}</h1><p class="sh-sub">${s.email}, indeks ${s.index}</p></div>
 <div class="acts"><button class="btn" data-act="open" data-m="assign">${icon('badge')}Przyznaj odznakę</button><button class="btn sec" data-act="open" data-m="adjust">${icon('coins')}Koryguj walutę</button><button class="btn sec" data-act="open" data-m="edit">${icon('edit')}Edytuj</button></div></div>
 <dl class="stats"><div class="stat"><dt>Ranga</dt><dd>${esc(r.name)}${nx?`<small>${s.tot} z ${nx.min} do rangi ${esc(nx.name)}</small>`:''}</dd>${nx?bar(s.tot-r.min,nx.min-r.min):''}</div>
 <div class="stat"><dt>Do wydania</dt><dd>${s.bal}</dd></div><div class="stat"><dt>Zebrane łącznie</dt><dd>${s.tot}</dd></div><div class="stat"><dt>Życia</dt><dd><span class="lv${s.lives?'':' z'}">${icon('heart')}</span>${s.lives}</dd></div></dl></section>`;}
function tabs(){const s=S.st,T=[['badges','Odznaki',s.badges.length],['items','Przedmioty',s.items.length],['hist','Historia waluty',S.hist.length]];
 return `<div class="tabs" role="tablist" aria-label="Sekcje studenta">${T.map(([k,l,n])=>`<button class="tab2" role="tab" id="tab-${k}" aria-selected="${S.tab===k}" aria-controls="tp" data-act="tab" data-v="${k}">${l}<span class="n">${n}</span></button>`).join('')}</div>`;}
function tBadges(){const s=S.st,bs=s.badges.map(id=>BADGE[id]);
 return bs.length?`<div class="bgrid">${bs.map(b=>`<article class="card badge full${S.fresh===b.id?' fresh':''}"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name">${esc(b.name)}</h3></div><div class="art">${glyph(b.glyph)}</div><p class="rules">${esc(b.rule)}</p><p class="flavor">${esc(b.flavor)}</p>
 <div class="card-foot"><span class="tag tag-disc">−${b.disc}% w sklepie</span><button class="linkbtn" data-act="revoke" data-id="${b.id}">Odbierz</button></div></div></div></article>`).join('')}</div>`
 :`<p class="expl">Student nie ma jeszcze żadnej odznaki.</p>`;}
function tItems(){const s=S.st;return `<p class="small" style="margin-bottom:14px">Przedmioty kupione w sklepie. Wykorzystanie przedmiotu (np. poprawę wejściówki) rozliczasz na zajęciach.</p><div class="ilist">${s.items.map(o=>{const it=ITEM[o.id];return `<article class="card item full"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name">${esc(it.name)}</h3><span class="cost"><b>${o.paid}</b></span></div><div class="art">${glyph(it.glyph)}</div><p class="rules">${esc(it.rules)}</p><p class="flavor">${esc(it.flavor)}</p><div class="card-foot"><span class="meta small">Kupione ${o.when}${o.paid<it.cost?`, ze zniżką z ${it.cost}`:''}</span></div></div></div></article>`;}).join('')}</div>`;}
function tHist(){let run=S.st.bal;const rows=S.hist.map(h=>{const r={...h,after:run};run-=h.amt;return r;}),f=S.filter==='all'?rows:rows.filter(r=>r.type===S.filter);
 const fc=(k,l)=>`<button class="fchip" data-act="filter" data-v="${k}" aria-pressed="${S.filter===k}">${l}</button>`;
 return `<div class="ledh"><div class="filters" role="group" aria-label="Pokaż">${fc('all','Wszystkie')}${fc('earn','Nagrody')}${fc('spend','Zakupy')}${fc('corr','Korekty')}</div><span class="sp"></span><span class="small">Saldo: <b>${S.st.bal}</b>, zebrane łącznie: <b>${S.st.tot}</b></span></div>
 <div role="table" aria-label="Historia waluty"><div class="lrow h" role="row"><span role="columnheader">Kwota</span><span role="columnheader">Typ</span><span role="columnheader">Za co</span><span role="columnheader">Kiedy</span><span role="columnheader" style="text-align:right">Saldo po</span></div>
 ${f.length?f.map(r=>`<div class="lrow${r.fresh?' fresh':''}" role="row"><span class="amt ${r.type}" role="cell">${r.amt>0?'+':'−'}${Math.abs(r.amt)}</span><span role="cell"><span class="ty ${r.type}">${TL[r.type]}</span></span><span class="src" role="cell">${esc(r.t)}${r.ctx?`<small>${esc(r.ctx)}</small>`:''}</span><span class="dt" role="cell">${r.when}</span><span class="bal2" role="cell">${r.after}</span></div>`).join(''):`<p class="expl">Brak wpisów tego typu.</p>`}</div>`;}
/* ---------- modals ---------- */
const dlg=(h,id,cls='')=>`<div class="ovl" data-act="close"><div class="dlg ${cls}" role="dialog" aria-modal="true" aria-labelledby="${id}" data-act="noop"><div class="dlg-in"><span class="grab"></span>${h}</div></div></div>`;
function mEdit(){const M=S.modal;return dlg(`<h2 class="h2" id="md">Edytuj studenta</h2><p>${esc(S.st.name)}. Imię, nazwisko i e-mail pochodzą z konta studenta.</p>
 <div class="fld"><p class="lbl" id="l-lv">Życia</p><div class="nstep" role="group" aria-labelledby="l-lv"><button data-act="mlv" data-d="-1" aria-label="Odbierz życie"${M.lives?'':' disabled'}>${icon('minus')}</button><output aria-live="polite">${M.lives}</output><button data-act="mlv" data-d="1" aria-label="Dodaj życie">${icon('plus')}</button></div><span class="hint">Życie odbierasz za nieusprawiedliwioną nieobecność. Przy 0 życiach student kupi tylko przedmioty dostępne przy 0 życiach.</span></div>
 <div class="fsec" style="margin-top:22px;padding-top:18px;border-top:1px solid var(--line)"><p class="lbl">Usuń z grupy</p><p class="small">Student straci dostęp do grupy. Dołączy ponownie tylko z nowym kodem.</p><button class="btn sec sm" style="margin-top:10px" data-act="kick">${icon('trash')}Usuń z grupy</button></div>
 <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="saveEdit"${M.lives===S.st.lives?' disabled':''} data-focus>Zapisz</button></div>`,'md');}
function unlocks(id){return {un:ITEMS.filter(it=>(it.req&&it.req.badges||[]).includes(id)).map(it=>it.name),di:ITEMS.filter(it=>(it.discBadges||[]).includes(id)).map(it=>it.name)};}
function mAssign(){const M=S.modal,q=(M.q||'').toLowerCase(),list=BADGES.filter(b=>!q||b.name.toLowerCase().includes(q)),sel=M.sel&&BADGE[M.sel],u=sel&&unlocks(sel.id);
 return dlg(`<h2 class="h2" id="md">Przyznaj odznakę</h2><p>${esc(S.st.name)} ma ${S.st.badges.length} z ${BADGES.length} odznak.</p>
 <label class="search" style="width:100%;margin-top:14px">${icon('search')}<input type="search" data-q placeholder="Szukaj odznaki" value="${esc(M.q||'')}" aria-label="Szukaj odznaki"></label>
 <ul class="bpick" role="radiogroup" aria-label="Odznaki">${list.map(b=>{const has=S.st.badges.includes(b.id);return `<li><button class="bp" role="radio" aria-checked="${M.sel===b.id}" data-act="pick" data-id="${b.id}"${has?' disabled':''}>${mini('badge',b.glyph)}<span><b>${esc(b.name)}</b><small>${esc(b.rule)}</small></span><span class="st2">${has?'Ma już':`−${b.disc}%`}</span></button></li>`;}).join('')||'<li class="expl">Brak odznak o tej nazwie.</li>'}</ul>
 ${sel?`<p class="expl effect">Po przyznaniu: <b>−${sel.disc}%</b> na przedmioty, które uwzględniają tę odznakę${u.di.length?` (${esc(andList(u.di))})`:''}.${u.un.length?` Odblokuje zakup: <b>${esc(andList(u.un))}</b>.`:''} Zobaczy ją w swojej talii.</p>`:''}
 <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="doAssign"${sel?'':' disabled'}>${sel?`Przyznaj „${esc(sel.name)}”`:'Wybierz odznakę'}</button></div>`,'md','dlg-review');}
function mAdjust(){const M=S.modal,a=+M.amt||0,sg=M.sign,d=sg*a,s=S.st,nb=s.bal+d,nt=s.tot+Math.max(0,d),r0=RANKS[rankIdx(s.tot)],r1=RANKS[rankIdx(Math.max(0,nt))],bad=nb<0;
 return dlg(`<h2 class="h2" id="md">Koryguj walutę</h2><p>${esc(s.name)} ma teraz ${s.bal} ${curA(s.bal)} do wydania.</p>
 <div class="seg3" role="group" aria-label="Rodzaj korekty"><button data-act="sign" data-v="1" aria-pressed="${sg===1}">Dodaj</button><button data-act="sign" data-v="-1" aria-pressed="${sg===-1}">Odejmij</button></div>
 <div class="fld"><label for="m-amt">Ile</label><div class="price-row"><div class="inp num${bad?' bad':''}"><input id="m-amt" type="number" min="1" data-amt value="${M.amt||''}" placeholder="0" data-focus${bad?' aria-invalid="true" aria-describedby="e-amt"':''}></div><span class="tok" style="--s:30px"><span><svg viewBox="0 0 24 24">${CI.carrot}</svg></span></span></div>${bad?`<p class="err" id="e-amt">${icon('alert')}Student ma tylko ${s.bal} do wydania.</p>`:''}</div>
 <div class="fld"><label for="m-why">Powód <small>(widoczny w historii studenta)</small></label><div class="inp"><input id="m-why" data-why value="${esc(M.why||'')}" placeholder="np. Pomyłka przy ocenianiu Laboratoriów 2"></div></div>
 ${a&&!bad?`<dl class="cprev2"><dt>Do wydania</dt><dd>${s.bal} → ${nb}</dd><dt>Zebrane łącznie</dt><dd>${s.tot}${nt!==s.tot?` → ${nt}`:' (bez zmian)'}</dd>${r1!==r0?`<dt>Ranga</dt><dd>${esc(r0.name)} → ${esc(r1.name)}</dd>`:''}</dl><p class="small" style="margin-top:8px">${d>0?'Dodanie podnosi też sumę zebranych, więc może podnieść rangę.':'Odjęcie zmniejsza tylko to, co student ma do wydania. Suma zebranych i ranga zostają bez zmian.'}</p>`:''}
 <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="doAdjust"${a&&!bad?'':' disabled'}>${a?`${sg>0?'Dodaj':'Odejmij'} ${a}`:'Podaj kwotę'}</button></div>`,'md');}
function mRevoke(){const b=BADGE[S.modal.id],u=unlocks(b.id);return dlg(`<h2 class="h2" id="md">Odebrać odznakę „${esc(b.name)}”?</h2><p>${esc(S.st.name)} straci zniżkę −${b.disc}%${u.un.length?` i możliwość zakupu: ${esc(andList(u.un))}`:''}. Kupione wcześniej przedmioty zostają.</p>
 <div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Anuluj</button><button class="btn" data-act="doRevoke">Odbierz odznakę</button></div>`,'md');}
function layer(){const L=app.querySelector('#layer');if(!S.modal){L.innerHTML='';L.classList.remove('on');return;}L.classList.add('on');
 L.innerHTML={edit:mEdit,assign:mAssign,adjust:mAdjust,revoke:mRevoke}[S.modal.m]();const f=L.querySelector('[data-focus]')||L.querySelector('[data-q]');if(f)f.focus();}
/* ---------- shell ---------- */
const ACT={noop(){},theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},hint(){hint('Not part of this screen.');},
 tab(a){S.tab=a.dataset.v;S.fresh=null;render(true);},filter(a){S.filter=a.dataset.v;render(true);},
 open(a){const m=a.dataset.m;S.modal=m==='edit'?{m,lives:S.st.lives}:m==='adjust'?{m,sign:1,amt:'',why:''}:{m,q:'',sel:null};layer();},close(){S.modal=null;layer();},
 mlv(a){S.modal.lives=Math.max(0,S.modal.lives+ +a.dataset.d);layer();},saveEdit(){const d=S.modal.lives-S.st.lives;S.st.lives=S.modal.lives;S.modal=null;render(true);toast(icon('heart')+(d<0?`Odebrano ${-d} ${pl(-d,'życie','życia','żyć')}. ${esc(S.st.name)} ma teraz ${S.st.lives}.`:`${esc(S.st.name)} ma teraz ${S.st.lives} ${pl(S.st.lives,'życie','życia','żyć')}.`));},
 kick(){S.modal=null;layer();toast(icon('check')+'Usunięto z grupy (makieta).');},
 pick(a){S.modal.sel=a.dataset.id;layer();},doAssign(){const b=BADGE[S.modal.sel];S.st.badges.push(b.id);S.fresh=b.id;S.tab='badges';S.modal=null;render(true);toast(icon('badge')+`Przyznano odznakę „${esc(b.name)}”.`);},
 revoke(a){S.modal={m:'revoke',id:a.dataset.id};layer();},doRevoke(){const b=BADGE[S.modal.id];S.st.badges=S.st.badges.filter(x=>x!==b.id);S.modal=null;render(true);toast(icon('check')+`Odebrano odznakę „${esc(b.name)}”.`);},
 sign(a){S.modal.sign=+a.dataset.v;layer();},doAdjust(){const M=S.modal,d=DB.adjust(S.st,M.sign*(+M.amt),M.why.trim());S.modal=null;S.tab='hist';S.filter='all';render(true);toast(icon('coins')+`${d>0?'Dodano':'Odjęto'} ${Math.abs(d)}. Saldo: ${S.st.bal}.`);}};
ON('input',e=>{const t=e.target,M=S.modal;if(!M)return;
 if(t.dataset.q!=null){M.q=t.value;layer();const i=app.querySelector('[data-q]');i.focus();i.setSelectionRange(i.value.length,i.value.length);}
 if(t.dataset.amt!=null){M.amt=t.value.replace(/[^0-9]/g,'');layer();const i=app.querySelector('[data-amt]');i.focus();}
 if(t.dataset.why!=null)M.why=t.value;});
DON('keydown',e=>{if(e.key==='Escape'&&S.modal)ACT.close();});

delete ACT.theme;
ACT.hint = () => hint('Not wired in this mockup.');

reg('student', {
  act: ACT, layer,
  closeLayer() { S.modal = null; },
  setView(v, o) {
    if (o && o.i != null) DB.selIdx = o.i;
    S.filter = 'all'; S.fresh = null;
    const tab = o && o.tab;
    S.tab = (tab === 'hist') ? 'hist' : (tab === 'assign' || tab === 'adjust') ? 'badges' : 'badges';
    S.modal = tab === 'assign' ? {m: 'assign', q: '', sel: null} : tab === 'adjust' ? {m: 'adjust', sign: 1, amt: '', why: ''} : null;
  },
  page() { return `<div class="page">${sheet()}${tabs()}<section class="panel tp" id="tp" role="tabpanel" aria-labelledby="tab-${S.tab}">${{badges: tBadges, items: tItems, hist: tHist}[S.tab]()}</section></div>`; }
});
})();
