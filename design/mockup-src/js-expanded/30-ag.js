/* ===== module: ag (grading sheets + templates, from t/ag.html) ===== */
(() => {
const ON = (t, f) => on('ag', t, f), DON = (t, f) => ondoc('ag', t, f);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
/*SHARED*/
Object.assign(IC,{minus:'<path d="M5 12h14"/>',x:'<path d="M6 6l12 12M18 6L6 18"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',archive:'<path d="M3 4h18v5H3zM5 9v11h14V9M10 13h4"/>',trash:'<path d="M4 6h16M9 6V3h6v3M6 6l1 15h10l1-15"/>',
 up:'<path d="M6 15l6-6 6 6"/>',grip:'<path class="fill" d="M8 5h2.5v2.5H8zM13.5 5H16v2.5h-2.5zM8 10.75h2.5v2.5H8zM13.5 10.75H16v2.5h-2.5zM8 16.5h2.5V19H8zM13.5 16.5H16V19h-2.5z"/>',
 text:'<path d="M4 6h16M4 12h10M4 18h13"/>',eye:'<path d="M2.5 12S6 6 12 6s9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6z"/><path d="M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z"/>',eyeOff:'<path d="M3 3l18 18M10.6 6.1A10 10 0 0 1 12 6c6 0 9.5 6 9.5 6a17 17 0 0 1-3 3.6M6.1 7.9A17 17 0 0 0 2.5 12S6 18 12 18a9.7 9.7 0 0 0 4-.9"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const tok=s=>`<span class="tok" style="--s:${s}px"><span><svg viewBox="0 0 24 24">${CI.carrot}</svg></span></span>`;
const RAB="url('__RABBITS__')";
const clone=o=>JSON.parse(JSON.stringify(o));
const LAB=[['Punktualny/a',2,'Rekrut stawił się na zbiórce floty i nie zgubił się w nadprzestrzeni.'],['Obecny/a',2,'Królik zameldował się na pokładzie.'],['Wejściówka zaliczona',1,''],['Wejściówka na poziomie co najmniej średniej grupy',1,''],['Wejściówka na maxa',2,'Lądowanie idealne, bez jednej rysy.'],['Zgłoszenie się do zrobienia zadania',1,''],['Samodzielnie i poprawnie zrobione zadanie',1,''],['Pomoc innym',1,'Holowanie uszkodzonego statku kolegi.'],['Ciekawa uwaga',1,''],['Udział w dyskusji',1,''],['Odpowiedź na pytanie wiedzy prowadzącego',1,'']].map(([name,prize,story])=>({name,prize,story}));
const POD=[['Kolokwium zaliczone',3,''],['Kolokwium na maxa',5,''],['Aktywność w semestrze',2,''],['Projekt oddany w terminie',3,'']].map(([name,prize,story])=>({name,prize,story}));
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',view:'list',modal:null,dlg:null,err:{},ed:null,orig:'',drag:null,
 tpls:[{id:'lab',name:'Laboratoria',cats:LAB},{id:'pod',name:'Podsumowanie',cats:POD}],
 groups:[{tpl:'lab',name:'Laboratoria 1',aw:86},{tpl:'lab',name:'Laboratoria 2',aw:79},{tpl:'lab',name:'Laboratoria 3',aw:90,mod:1},{tpl:'lab',name:'Laboratoria 4',aw:74},{tpl:'lab',name:'Laboratoria 5',aw:21,cur:1},{tpl:'pod',name:'Podsumowanie 1',aw:31}]};
const maxOf=cats=>cats.filter(c=>!c.hidden).reduce((a,c)=>a+(+c.prize||0),0);
const TPL=id=>S.tpls.find(t=>t.id===id);
const dirty=()=>JSON.stringify(S.ed)!==S.orig;
/* ---------- list ---------- */
function tplPanel(t){const gs=S.groups.filter(g=>g.tpl===t.id&&!g.del).slice().reverse();
 return `<section class="panel tpl" aria-labelledby="t-${t.id}"><div class="tpl-h"><div><h2 id="t-${t.id}">${esc(t.name)}</h2><p class="tpl-meta">Szablon: ${t.cats.length} ${pl(t.cats.length,'kategoria','kategorie','kategorii')}, do ${maxOf(t.cats)} marchewek na studenta za arkusz.</p></div><span class="sp"></span>
 <button class="btn sec sm" data-act="go" data-v="edittpl" data-t="${t.id}">Edytuj szablon</button><button class="btn sm" data-act="create" data-t="${t.id}">${icon('plus')}Utwórz arkusz</button></div>
 ${gs.length?`<ul class="agl">${gs.map((g,i)=>{const full=g.aw>=60;return `<li class="ag${g.fresh?' fresh':''}"><span class="ag-n"><b>${esc(g.name)}</b>${g.mod?'<span class="tag t-mod">Zmienione kolumny</span>':''}</span>
  <span class="ag-s">${g.aw?`Przyznano ${g.aw} ${pl(g.aw,'nagrodę','nagrody','nagród')}`:'Jeszcze nic nie przyznano'}</span>
  <span class="ag-a"><button class="btn sm${i===0?'':' sec'}" data-act="grade">Oceń</button><button class="iconbtn" data-act="go" data-v="group" aria-label="Ustawienia: ${esc(g.name)}" title="Ustawienia arkusza">${icon('settings')}</button></span></li>`;}).join('')}</ul>`
 :`<p class="expl">Z tego szablonu nie utworzono jeszcze arkuszy.</p>`}</section>`;}
const bar=(v,m)=>`<div class="bar"><i style="--p:${Math.round(v/m*100)}%"></i></div>`;
function viewList(){return `<section class="panel phead"><div class="phead-t"><h1>Arkusze ocen</h1><p class="lead">Arkusze pogrupowane według szablonów. Najnowsze są na górze.</p></div><button class="btn sec" data-act="go" data-v="newtpl">${icon('plus')}Nowy szablon</button></section>${S.tpls.filter(x=>!x.del).map(tplPanel).join('')}`;}
/* ---------- category editor (template + per-group) ---------- */
function catRow(c,i,n,grp){const aw=grp?c.aw||0:0,lk=aw>0,e=S.err['c'+i];
 return `<li class="cat${c.hidden?' hid':''}" draggable="true" data-i="${i}"><span class="handle" title="Przeciągnij, aby zmienić kolejność" aria-hidden="true">${icon('grip')}</span>
 <div class="cat-b"><div class="inp${e?' bad':''}"><input data-c="name" data-i="${i}" value="${esc(c.name)}" placeholder="Za co, np. Pomoc innym" aria-label="Kategoria ${i+1}: za co"${e?' aria-invalid="true"':''}></div>${e?`<p class="err">${icon('alert')}${e}</p>`:''}
 ${c.story||c.showStory?`<div class="inp story-t"><textarea data-c="story" data-i="${i}" rows="1" placeholder="Opis fabularny, np. Holowanie uszkodzonego statku" aria-label="Opis fabularny kategorii ${i+1}">${esc(c.story)}</textarea></div>`:`<button class="linkbtn story-add" data-act="story" data-i="${i}">${icon('text')}Dodaj opis fabularny</button>`}
 ${grp&&c.only?'<span class="tag t-only">Tylko w tym arkuszu</span> ':''}${c.hidden?'<span class="tag t-hid">Ukryta w tabeli ocen</span>':''}
 ${lk?`<p class="lockn">${icon('lock')}<span>Przyznano ${aw} ${pl(aw,'nagrodę','nagrody','nagród')}. Kolumny nie można usunąć, można ją ukryć.${c.prize!==c.p0?' Nowa wartość obejmie tylko przyszłe nagrody.':''}</span></p>`:''}</div>
 <div class="cat-p"><div class="inp sm${S.err['p'+i]?' bad':''}"><input type="number" min="1" data-c="prize" data-i="${i}" value="${c.prize}" aria-label="Nagroda za kategorię ${i+1}"></div>${tok(26)}</div>
 <div class="cat-a"><button class="iconbtn" data-act="mv" data-i="${i}" data-d="-1" aria-label="Przesuń wyżej"${i?'':' disabled'}>${icon('up')}</button><button class="iconbtn" data-act="mv" data-i="${i}" data-d="1" aria-label="Przesuń niżej"${i<n-1?'':' disabled'}>${icon('chevDown')}</button>
 ${lk?`<button class="iconbtn" data-act="hide" data-i="${i}" aria-label="${c.hidden?'Pokaż w tabeli ocen':'Ukryj w tabeli ocen'}" title="${c.hidden?'Pokaż':'Ukryj'} w tabeli ocen">${icon(c.hidden?'eye':'eyeOff')}</button>`:`<button class="iconbtn" data-act="rm" data-i="${i}" aria-label="Usuń kategorię ${i+1}">${icon('trash')}</button>`}</div></li>`;}
function editor(){const grp=S.view==='group',ed=S.ed,n=ed.cats.length;
 return `${S.view==='edittpl'?`<p class="info">${icon('grid')}<span><b>Zmiany dotyczą tylko arkuszy utworzonych od teraz.</b> Laboratoria 1–5 zostają bez zmian.</span></p>`:''}
 ${grp?`<p class="info">${icon('lock')}<span><b>W tym arkuszu przyznano już 21 nagród.</b> Zmiany kolumn dotyczą tylko przyszłych nagród. Szablon Laboratoria się nie zmienia.</span></p>`:''}
 <div class="fsec"><div class="fld" style="margin-top:0"><label for="f-name">${grp?'Nazwa arkusza':'Nazwa szablonu'}</label><div class="inp${S.err.name?' bad':''}"><input id="f-name" data-f="name" value="${esc(ed.name)}" placeholder="${grp?'np. Laboratoria 5 (14.10)':'np. Laboratoria'}"${S.err.name?' aria-invalid="true" aria-describedby="e-name"':''}></div>${S.err.name?`<p class="err" id="e-name">${icon('alert')}${S.err.name}</p>`:''}${grp?'':'<span class="hint">Nowe arkusze dostaną nazwę szablonu z kolejnym numerem, np. Laboratoria 6.</span>'}</div></div>
 <div class="fsec"><h2 class="h3">${grp?'Kolumny w tabeli ocen':'Kategorie nagród'}</h2><p class="hint">Każda kategoria to kolumna w tabeli ocen. Kolejność tutaj to kolejność kolumn.</p>
 <ul class="cats" id="cats">${ed.cats.map((c,i)=>catRow(c,i,n,grp)).join('')}</ul>${S.err.cats?`<p class="err">${icon('alert')}${S.err.cats}</p>`:''}
 <button class="btn sec addcat" data-act="add">${icon('plus')}Dodaj ${grp?'kolumnę':'kategorię'}</button>
 <p class="expl" id="sum">${sumText()}</p></div>
 ${S.view!=='newtpl'?`<div class="fsec"><h2 class="h3">Usuwanie</h2><p class="hint">${grp?'Arkusz zniknie z listy, a przyznane nagrody zostają u studentów i w ich historii.':'Szablon zniknie z listy, a utworzone z niego arkusze zostają.'}</p><button class="btn sec" style="margin-top:12px" data-act="archive">${icon('trash')}Usuń ${grp?'arkusz':'szablon'}</button></div>`:''}`;}
function sumText(){const v=S.ed.cats.filter(c=>!c.hidden);return `${v.length} ${pl(v.length,'kolumna','kolumny','kolumn')} w tabeli ocen. Student może zdobyć do <b>${maxOf(S.ed.cats)}</b> marchewek za arkusz.`;}
function gridPrev(){const v=S.ed.cats.filter(c=>!c.hidden);return `<details class="pvd" open><summary>Podgląd tabeli ocen ${icon('chevDown')}</summary><section class="panel pv"><h3>Nagłówek tabeli ocen</h3><div class="gprev"><table class="grid"><thead><tr><th class="th-stu">Student</th>${v.map(c=>`<th><div class="thc"><span class="thn">${esc(c.name||'…')}</span><span class="cost sm"><b>+${+c.prize||0}</b></span></div></th>`).join('')}</tr></thead><tbody>${['Adam Pawłowski','Barbara Kowalewska'].map(s=>`<tr><th class="td-stu">${s}</th>${v.map(()=>'<td><span class="cell sm empty"></span></td>').join('')}</tr>`).join('')}</tbody></table></div><span class="hint">Najedź na nagłówek w prawdziwej tabeli, żeby zobaczyć opis fabularny.</span></section></details>`;}
/* ---------- shell ---------- */
function refresh(){const p=app.querySelector('.pcol');if(p){const o=p.querySelector('.pvd').open;p.innerHTML=gridPrev();p.querySelector('.pvd').open=o;}const s=app.querySelector('#sum');if(s)s.innerHTML=sumText();
 const d=dirty(),k=app.querySelector('#dk'),b=app.querySelector('#sv');if(k)k.textContent=d?'Niezapisane zmiany':'Brak zmian';if(b)b.disabled=!d;}
/* ---------- modal ---------- */
function layer(){const L=app.querySelector('#layer');if(!S.modal&&!S.dlg){L.innerHTML='';L.classList.remove('on');return;}L.classList.add('on');let h;
 if(S.dlg)h=`<h2 class="h2" id="dt">Odrzucić zmiany?</h2><p>Niezapisane zmiany zostaną utracone.</p><div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Wróć do edycji</button><button class="btn" data-act="discard">Odrzuć zmiany</button></div>`;
 else{const M=S.modal,t=TPL(M.tpl),n0=S.groups.filter(g=>g.tpl===t.id).length+1,names=Array.from({length:M.count},(_,k)=>`${t.name} ${n0+k}`);
  h=`<h2 class="h2" id="dt">Nowy arkusz z szablonu ${esc(t.name)}</h2><p>Każdy arkusz dostanie ${t.cats.length} ${pl(t.cats.length,'kategorię','kategorie','kategorii')} z szablonu. Kolumny zmienisz później w ustawieniach arkusza.</p>
  <div class="seg3" role="group" aria-label="Ile arkuszy"><button data-act="mmode" data-v="one" aria-pressed="${M.mode==='one'}">Jeden arkusz</button><button data-act="mmode" data-v="many" aria-pressed="${M.mode==='many'}">Kilka naraz</button></div>
  ${M.mode==='one'?`<div class="fld"><label for="m-name">Nazwa</label><div class="inp"><input id="m-name" data-m="name" value="${esc(M.name??names[0])}" data-focus></div><span class="hint">Możesz dopisać datę, np. ${esc(names[0])} (14.10).</span></div>`
  :`<div class="fld"><p class="lbl" id="m-cnt">Ile arkuszy utworzyć</p><div class="nstep" role="group" aria-labelledby="m-cnt"><button data-act="mcount" data-d="-1" aria-label="Mniej">${icon('minus')}</button><output aria-live="polite">${M.count}</output><button data-act="mcount" data-d="1" aria-label="Więcej" data-focus>${icon('plus')}</button></div><div class="names" aria-label="Nazwy">${names.map(x=>`<span class="oct" style="--c:4px">${esc(x)}</span>`).join('')}</div></div>`}
  <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="mgo">Utwórz ${M.mode==='one'?'':`${M.count} `}${pl(M.mode==='one'?1:M.count,'arkusz','arkusze','arkuszy')}</button></div>`;}
 L.innerHTML=`<div class="ovl" data-act="close"><div class="dlg" role="dialog" aria-modal="true" aria-labelledby="dt" data-act="noop"><div class="dlg-in"><span class="grab"></span>${h}</div></div></div>`;const f=L.querySelector('[data-focus]');if(f)f.focus();}
/* ---------- actions ---------- */
function open(v,tid){S.view=v;S.err={};S.modal=null;S.dlg=null;
 if(v==='newtpl')S.ed={name:'',cats:[{name:'Obecność',prize:2,story:''},{name:'',prize:1,story:''}]};
 if(v==='edittpl')S.ed=clone(TPL(tid||'lab'));
 if(v==='group'){S.ed={name:'Laboratoria 5',cats:[...clone(LAB).map((c,i)=>({...c,aw:[10,11][i]||0,p0:c.prize})),{name:'Prezentacja projektu',prize:3,story:'',only:1,aw:0,p0:3}]};}
 S.orig=v==='list'?'':JSON.stringify(S.ed);render();}
function validate(){S.err={};const e=S.ed;if(!e.name.trim())S.err.name=S.view==='group'?'Podaj nazwę arkusza.':'Podaj nazwę szablonu.';
 e.cats.forEach((c,i)=>{if(!c.name.trim())S.err['c'+i]='Podaj, za co jest nagroda.';if(!(+c.prize>=1)){S.err['p'+i]=1;S.err['c'+i]=S.err['c'+i]||'Nagroda musi wynosić co najmniej 1.';}});
 if(!e.cats.filter(c=>!c.hidden).length)S.err.cats='Dodaj co najmniej jedną widoczną kategorię.';return !Object.keys(S.err).length;}
const ACT={noop(){},theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},hint(){hint('Grading is in the main mockup.');},
 go(a){if(S.view!=='list'&&dirty()&&a.dataset.v==='list'){S.dlg=true;S.next='list';layer();return;}open(a.dataset.v,a.dataset.t);},
 create(a){S.modal={tpl:a.dataset.t,mode:'one',count:3};layer();},close(){S.modal=null;S.dlg=false;layer();},
 mmode(a){S.modal.mode=a.dataset.v;layer();},mcount(a){S.modal.count=Math.min(20,Math.max(2,S.modal.count+ +a.dataset.d));layer();},
 mgo(){const M=S.modal,t=TPL(M.tpl),n0=S.groups.filter(g=>g.tpl===t.id).length+1,nm=M.mode==='one'?[(M.name??`${t.name} ${n0}`).trim()||`${t.name} ${n0}`]:Array.from({length:M.count},(_,k)=>`${t.name} ${n0+k}`);
  S.groups.forEach(g=>{g.fresh=0;});nm.forEach(n=>S.groups.push({tpl:t.id,name:n,aw:0,fresh:1}));S.modal=null;render(true);toast(icon('check')+(nm.length>1?`Utworzono: ${esc(nm[0])} – ${esc(nm[nm.length-1])}.`:`Utworzono: ${esc(nm[0])}.`));},
 add(){S.ed.cats.push({name:'',prize:1,story:'',only:S.view==='group'?1:0,aw:0,p0:1});render(true);const i=app.querySelectorAll('[data-c=name]');i[i.length-1].focus();},
 rm(a){S.ed.cats.splice(+a.dataset.i,1);render(true);},hide(a){const c=S.ed.cats[+a.dataset.i];c.hidden=!c.hidden;render(true);},
 mv(a){const i=+a.dataset.i,j=i+ +a.dataset.d,c=S.ed.cats;[c[i],c[j]]=[c[j],c[i]];render(true);const b=app.querySelector(`[data-act=mv][data-i="${j}"][data-d="${a.dataset.d}"]`)||app.querySelector(`[data-act=mv][data-i="${j}"]`);if(b)b.focus();},
 story(a){S.ed.cats[+a.dataset.i].showStory=1;render(true);app.querySelector(`[data-c=story][data-i="${a.dataset.i}"]`).focus();},
 save(){if(!validate()){render(true);const f=app.querySelector('[aria-invalid="true"]');if(f)f.focus();return;}const v=S.view,ed=clone(S.ed);
  if(v==='newtpl'){S.tpls.push({id:'t'+Date.now(),name:ed.name,cats:ed.cats});open('list');toast(icon('check')+`Utworzono szablon „${esc(ed.name)}”.`);}
  else if(v==='edittpl'){const t=TPL(JSON.parse(S.orig).id);Object.assign(t,{name:ed.name,cats:ed.cats});open('list');toast(icon('check')+'Zapisano szablon. Nowe arkusze dostaną te kategorie.');}
  else{const g=S.groups.find(x=>x.cur);if(g)g.mod=1;open('list');toast(icon('check')+'Zapisano ustawienia arkusza Laboratoria 5.');}},
 cancel(){if(dirty()&&S.view!=='newtpl'||S.view==='newtpl'&&S.ed.name){S.dlg=true;S.next='list';layer();}else open('list');},discard(){S.dlg=false;open('list');},
 archive(){const grp=S.view==='group';if(grp){const g=S.groups.find(x=>x.cur);if(g)g.del=1;}else{const t=TPL(JSON.parse(S.orig).id);if(t)t.del=1;}open('list');render(false);toast(icon('check')+(grp?'Usunięto arkusz Laboratoria 5. Przyznane nagrody zostają w historii studentów.':'Usunięto szablon. Utworzone z niego arkusze zostają.'));}};
ON('input',e=>{const t=e.target;if(t.dataset.m){S.modal.name=t.value;return;}
 if(t.dataset.f){S.ed.name=t.value;if(S.err.name&&t.value.trim()){delete S.err.name;t.parentNode.classList.remove('bad');const m=app.querySelector('#e-name');if(m)m.remove();}}
 if(t.dataset.c){const c=S.ed.cats[+t.dataset.i];c[t.dataset.c]=t.dataset.c==='prize'?(parseInt(t.value,10)||0):t.value;}refresh();});
ON('change',e=>{if(e.target.dataset.c==='prize')render(true);});
ON('dragstart',e=>{const li=e.target.closest('.cat');if(!li)return;S.drag=+li.dataset.i;li.classList.add('dragging');e.dataTransfer.effectAllowed='move';});
ON('dragover',e=>{const li=e.target.closest('.cat');if(!li||S.drag==null)return;e.preventDefault();app.querySelectorAll('.cat.over').forEach(x=>x.classList.remove('over'));li.classList.add('over');});
ON('drop',e=>{const li=e.target.closest('.cat');if(!li||S.drag==null)return;e.preventDefault();const c=S.ed.cats,[m]=c.splice(S.drag,1);c.splice(+li.dataset.i,0,m);S.drag=null;render(true);});
ON('dragend',()=>{S.drag=null;app.querySelectorAll('.cat').forEach(x=>x.classList.remove('over','dragging'));});
DON('keydown',e=>{if(e.key==='Escape'&&(S.modal||S.dlg))ACT.close();if(e.key==='Enter'&&e.target.dataset&&e.target.dataset.m){e.preventDefault();ACT.mgo();}});

const ROUTES_OF = {list: 't/sheets', newtpl: 't/sheet-template-new', edittpl: 't/sheet-template-edit', group: 't/sheet-settings'};
delete ACT.theme;
ACT.go = a => { const v = a.dataset.v; if (!v) return nav(a.dataset.to); if (v === 'list') return nav('t/sheets'); open(v, a.dataset.t); render(false); };
ACT.hint = () => hint('Not wired in this mockup.');
ACT.grade = () => nav('t/grade');

reg('ag', {
  act: ACT, layer,
  closeLayer() { S.modal = null; S.dlg = null; },
  setView(v, o) { open(v, (o && o.t) || (S.tpls[0] || {}).id); },
  page() {
    const v = S.view;
    setRoute(ROUTES_OF[v]);
    if (v === 'list') return `<div class="page">${viewList()}</div>`;
    const T = {newtpl: ['Nowy szablon arkusza', 'Nowy szablon'], edittpl: ['Edytuj szablon arkusza', S.orig && JSON.parse(S.orig).name], group: ['Ustawienia arkusza', 'Laboratoria 5']}[v];
    return `<div class="page"><section class="panel phead" style="display:block"><p class="crumbs"><a href="#/t/sheets" data-act="go" data-v="list">Arkusze ocen</a>${icon('chevRight')}<span>${esc(T[1])}</span></p><h1>${T[0]}</h1><p class="lead">${v === 'group' ? 'Zmiany dotyczą tylko tego arkusza.' : 'Podgląd obok pokazuje nagłówek tabeli ocen.'}</p></section>
      <div class="wiz"><section class="panel fcol">${editor()}</section><aside class="pcol" aria-label="Podgląd">${gridPrev()}</aside></div>
      <div style="margin-bottom:14px"><div class="panel wbar"><button class="linkbtn" data-act="cancel">Anuluj</button><span class="sp"></span>${v === 'newtpl' ? `<button class="btn" data-act="save">${icon('plus')}Utwórz szablon</button>` : `<span class="k" id="dk">${dirty() ? 'Niezapisane zmiany' : 'Brak zmian'}</span><button class="btn" id="sv" data-act="save"${dirty() ? '' : ' disabled'}>Zapisz zmiany</button>`}</div></div></div>`;
  }
});
})();
