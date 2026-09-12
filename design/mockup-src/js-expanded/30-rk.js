/* ===== module: rk (ranking + supporting teachers, from t/rk.html) ===== */
(() => {
const ON = (t, f) => on('rk', t, f), DON = (t, f) => ondoc('rk', t, f);
const STU = DB.students;
const ME = DB.me().name;
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
/*SHARED*/
Object.assign(IC,{minus:'<path d="M5 12h14"/>',x:'<path d="M6 6l12 12M18 6L6 18"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',edit:'<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13 7l4 4"/>',trash:'<path d="M4 6h16M9 6V3h6v3M6 6l1 15h10l1-15"/>',eyeOff:'<path d="M3 3l18 18M10.6 6.1A10 10 0 0 1 12 6c6 0 9.5 6 9.5 6a17 17 0 0 1-3 3.6M6.1 7.9A17 17 0 0 0 2.5 12S6 18 12 18a9.7 9.7 0 0 0 4-.9"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const glyph=n=>`<svg class="gph" viewBox="0 0 64 64" aria-hidden="true">${GL[n]||''}</svg>`;
const mini=g=>`<span class="card item mc"><span class="card-f"><span class="card-i">${glyph(g)}</span></span></span>`;
const initials=n=>n.split(/\s+/).map(w=>w[0]).join('').slice(0,2).toUpperCase(),hue=n=>[...n].reduce((a,c)=>a+c.charCodeAt(0),0)%5;
const av=(n,c='sm')=>`<span class="av ${c}" data-h="${hue(n)}" aria-hidden="true">${initials(n)}</span>`;
const svgUrl=s=>`url('data:image/svg+xml;charset=utf-8,${encodeURIComponent(s)}')`;
const ART={kk:"url('__RABBITS__')",atl:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90"><rect width="160" height="90" fill="#0E4F5C"/><path d="M-10 50q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#5CCFC6" stroke-width="6" fill="none"/></svg>'),alg:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90"><rect width="160" height="90" fill="#17492F"/><path d="M80 18l20 27-20 27-20-27z" stroke="#7CD6A0" stroke-width="6" fill="none"/></svg>')};
const gchip=g=>`<span class="gchip"><span class="gthumb" style="background-image:${ART[g]}"></span><span>${GN[g]}</span></span>`;
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',view:'rt',get visible(){return DB.group.ranking;},set visible(v){DB.group.ranking=v;},get mode(){return DB.group.rankMode;},set mode(v){DB.group.rankMode=v;},modal:null,pop:false,
 get teachers(){return DB.teachers;},
 pool:[['Janusz Nowakowski','janusz.nowakowski@example.com'],['Anna Wiśniewska','anna.wisniewska@example.com'],['Piotr Zieliński','piotr.zielinski@example.com'],['Marta Kaczmarek','marta.kaczmarek@example.com'],['Tomasz Wróbel','tomasz.wrobel@example.com']],
 notes:[{u:1,stu:'Sebastian Alejandro',item:'popr',g:'kk',t:'10:21',d:'Dziś'},{u:1,stu:'Barbara Kowalewska',item:'min5',g:'kk',t:'09:58',d:'Dziś'},{u:1,stu:'Dawid Zebra',name:'Eliksir energetyczny',glyph:'flask',g:'atl',t:'08:40',d:'Dziś'},
  {u:0,stu:'Sebastian Alejandro',name:'Zwolnienie z wejściówki',glyph:'paperCheck',g:'alg',t:'18:43',d:'Wczoraj'},{u:0,stu:'Adrian Kowalski',item:'kons',g:'kk',t:'17:10',d:'Wczoraj'},{u:0,stu:'Adam Pawłowski',item:'oneup',g:'kk',t:'10.06',d:''}]};
const isStu=()=>S.view==='rs';
/* ---------- ranking ---------- */
function places(){let last=null,pos=0;return STU.slice().sort((a,b)=>b.tot-a.tot).map((s,i)=>{if(s.tot!==last){pos=i+1;last=s.tot;}return{...s,pos};});}
function rows(stu){let list=places();const me=list.find(s=>s.name===ME);
 if(stu&&S.mode==='podium'){const top=list.filter(s=>s.pos<=3);list=me.pos<=3?top:[...top,{gap:1},me];}
 return list.map(s=>{if(s.gap)return `<div class="rk-row gap2" role="row"><span class="gapt" role="cell">…</span><span class="nm" role="cell"><span class="none">Pozostałe miejsca są ukryte</span></span></div>`;
 const mine=stu&&s.name===ME,r=RANKS[rankIdx(s.tot)],nk=s.nick?esc(s.nick):'<span class="none">Bez pseudonimu</span>';
 return `<div class="rk-row${mine?' me':''}" role="row"><span role="cell"><span class="pos${s.pos<=3?' p'+s.pos:''}" aria-label="Miejsce ${s.pos}">${s.pos}</span></span><span class="nm" role="cell"><b>${nk}${mine?'<span class="youtag">Ty</span>':''}</b>${stu?'':`<small>${esc(s.name)}</small>`}</span><span class="rk-r" role="cell">${esc(r.name)}</span><span class="sc" role="cell">${s.tot}</span></div>`;}).join('');}
const table=stu=>`<section class="panel rkt" role="table" aria-label="Ranking"><div class="rk-row h" role="row"><span role="columnheader">Miejsce</span><span role="columnheader">${stu?'Pseudonim':'Pseudonim i student'}</span><span role="columnheader">Ranga</span><span role="columnheader" style="text-align:right">Zebrane</span></div>${rows(stu)}</section>`;
function vRT(){const note=!S.visible?`<p class="info" style="margin-top:18px">${icon('eyeOff')}<span><b>Ranking jest ukryty przed studentami.</b> Ty nadal go widzisz.</span></p>`
 :S.mode==='podium'?`<p class="info" style="margin-top:18px">${icon('eyeOff')}<span><b>Studenci widzą tylko podium i swoje miejsce.</b> Nikt nie zobaczy, kto jest na końcu listy. Ty widzisz wszystkich.</span></p>`:'';
 return `<section class="panel phead"><div class="phead-t"><h1>Ranking</h1><p class="lead">Kolejność według łącznie zebranych marchewek. Studenci widzą tylko pseudonimy, Ty widzisz też imiona i nazwiska.</p></div>
 <div class="rkctl"><div class="swrow inline"><button class="sw" role="switch" aria-checked="${S.visible}" data-act="vis" aria-labelledby="l-vis"><i></i></button><span><b id="l-vis">Widoczny dla studentów</b></span></div>
 ${S.visible?`<div class="seg3" role="group" aria-label="Co widzą studenci"><button data-act="mode" data-v="podium" aria-pressed="${S.mode==='podium'}">Podium i własne miejsce</button><button data-act="mode" data-v="full" aria-pressed="${S.mode==='full'}">Pełny ranking</button></div>`:''}</div></section>
 ${note}${table(false)}<p class="small" style="margin-top:12px">Remis daje to samo miejsce. Studenci bez pseudonimu są widoczni jako „Bez pseudonimu”.</p>`;}
function vRS(){const me=places().find(s=>s.name===ME);
 const head=`<section class="panel phead" style="display:block"><h1>Ranking</h1><p class="lead">${!S.visible?'Prowadzący ukrył ranking na razie.':S.mode==='podium'?'Prowadzący pokazuje tylko podium. Swoje miejsce widzisz tylko Ty.':'Kolejność według łącznie zebranych marchewek.'}</p>
 <div class="mine">${S.visible?`<div><b>${me.pos}.</b><small>Twoje miejsce z ${STU.length}</small></div>`:''}<div><b>${me.tot}</b><small>Zebrane łącznie</small></div>
 <div class="nick">Twój pseudonim w tej grupie: <b>${me.nick?esc(me.nick):'brak'}</b><button class="linkbtn" data-act="nick">${icon('edit')}Zmień</button></div></div></section>`;
 return head+(S.visible?table(true):`<section class="panel hidden-p"><div class="gm-ic oct" style="--c:12px">${icon('eyeOff')}</div><h2 class="h2">Ranking jest teraz ukryty</h2><p class="lead" style="margin:8px auto 0">Zbieraj dalej marchewki. Gdy prowadzący włączy ranking, zobaczysz tu swoje miejsce.</p></section>`);}
/* ---------- teachers ---------- */
function vTeachers(){return `<section class="panel phead"><div class="phead-t"><h1>Nauczyciele</h1><p class="lead">Nauczyciele wspomagający pomagają prowadzić tę grupę. Grupę może usunąć tylko właściciel.</p></div><button class="btn" data-act="addT">${icon('plus')}Dodaj nauczyciela</button></section>
 <section class="panel tch"><div class="trow h"><span>Nauczyciel</span><span>Rola</span><span>Dodano</span><span></span></div>${S.teachers.map((t,i)=>`<div class="trow"><span class="s-n">${av(t.name)}<span style="min-width:0"><b>${esc(t.name)}</b><small>${t.email}</small></span></span>
 <span class="role">${t.owner?'Właściciel<small>Utworzył grupę</small>':'Nauczyciel wspomagający'}</span><span class="dt">${t.added}</span><span>${t.owner?'':`<button class="btn sec sm" data-act="rmT" data-i="${i}">${icon('trash')}Usuń</button>`}</span></div>`).join('')}</section>`;}
/* ---------- modals & popover ---------- */
const dlg=(h,id)=>`<div class="ovl" data-act="close"><div class="dlg" role="dialog" aria-modal="true" aria-labelledby="${id}" data-act="noop"><div class="dlg-in"><span class="grab"></span>${h}</div></div></div>`;
function mNick(){const M=S.modal;return dlg(`<h2 class="h2" id="mn">Pseudonim w grupie Kosmiczne króliki</h2><p>Widoczny w rankingu tylko w tej grupie. W innych grupach możesz mieć inny. Prowadzący widzi też Twoje imię i nazwisko.</p>
 <div class="fld"><label for="f-nick">Pseudonim</label><div class="inp${M.err?' bad':''}"><input id="f-nick" data-nick value="${esc(M.v)}" maxlength="24" autocomplete="off" data-focus${M.err?' aria-invalid="true" aria-describedby="e-nick"':''}></div>${M.err?`<p class="err" id="e-nick">${icon('alert')}${M.err}</p>`:''}<span class="hint">Do 24 znaków. Bez imienia i nazwiska, jeśli nie chcesz być rozpoznany.</span></div>
 <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="saveNick">Zapisz pseudonim</button></div>`,'mn');}
const FN=['Anna','Piotr','Marta','Tomasz','Katarzyna','Paweł','Magdalena','Krzysztof','Agnieszka','Michał','Ewa','Łukasz','Joanna','Marcin','Monika','Grzegorz','Aleksandra','Rafał','Barbara','Wojciech'],SN=['Nowak','Kowalczyk','Zając','Wróbel','Król','Mazur','Krawczyk','Dudek','Adamczyk','Pawlak','Sikora','Baran','Duda','Szewczyk','Michalak','Kaczmarek'],DEP=['Wydział Matematyki i Informatyki','Wydział Fizyki','Instytut Pedagogiki','Wydział Chemii'];
const norm=x=>x.normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/ł/g,'l').replace(/Ł/g,'L').toLowerCase();
const POOL=[{name:'Janusz Nowakowski',email:'janusz.nowakowski@example.com',dep:DEP[0]},...FN.flatMap((f,i)=>SN.map((n,j)=>({name:f+' '+n,email:norm(f)+'.'+norm(n)+'@example.com',dep:DEP[(i+j)%4]})))];
const hl=(n,q)=>{const i=norm(n).indexOf(q);return i<0?esc(n):esc(n.slice(0,i))+'<mark>'+esc(n.slice(i,i+q.length))+'</mark>'+esc(n.slice(i+q.length));};
function resHtml(){const q=norm((S.modal.q||'').trim()),inG=n=>S.teachers.some(t=>t.name===n);
 if(q.length<2)return `<p class="expl">Wpisz co najmniej 2 znaki imienia, nazwiska albo e-maila. W Twojej uczelni jest ${POOL.length} nauczycieli.</p>`;
 const res=POOL.filter(t=>norm(t.name+' '+t.email).includes(q));if(!res.length)return `<p class="expl">Brak wyników dla „${esc(S.modal.q)}”. Sprawdź pisownię albo wpisz e-mail.</p>`;
 return `<p class="n-sec">${res.length} ${pl(res.length,'wynik','wyniki','wyników')}${res.length>8?', pokazujemy 8 pierwszych':''}</p><ul class="tres">${res.slice(0,8).map(t=>`<li class="tr">${av(t.name)}<span class="tr-n"><b>${hl(t.name,q)}</b><small>${t.email}, ${t.dep}</small></span>${inG(t.name)?'<span class="st2">Już w grupie</span>':`<button class="btn sec sm" data-act="doAddT" data-n="${esc(t.name)}" aria-label="Dodaj ${esc(t.name)}">${icon('plus')}Dodaj</button>`}</li>`).join('')}</ul>${res.length>8?'<p class="small" style="margin-top:8px">Nie widzisz tej osoby? Wpisz więcej liter albo e-mail.</p>':''}`;}
function mAddT(){return dlg(`<h2 class="h2" id="ma">Dodaj nauczyciela</h2><p>Nauczyciel dostanie dostęp do grupy od razu po dodaniu.</p>
 <label class="search" style="width:100%;margin-top:14px">${icon('search')}<input type="search" data-tq value="${esc(S.modal.q||'')}" placeholder="Imię, nazwisko albo e-mail" aria-label="Szukaj nauczyciela" autocomplete="off" data-focus></label>
 <div id="tres-w" aria-live="polite">${resHtml()}</div><div class="dlg-b"><button class="btn sec" data-act="close">Zamknij</button></div>`,'ma');}
function mEnable(){const o=(v,t,d)=>`<button class="opt" role="radio" aria-checked="${S.modal.mode===v}" data-act="pickMode" data-v="${v}"><b>${t}</b><span>${d}</span></button>`;
 return dlg(`<h2 class="h2" id="me">Pokazać ranking studentom?</h2><p>Studenci zobaczą ranking od razu. Wybierz, ile mają widzieć.</p>
 <div class="opts" role="radiogroup" aria-label="Co widzą studenci" style="margin-top:14px">${o('podium','Podium i własne miejsce','Wszyscy widzą pierwsze 3 miejsca. Każdy widzi też swoje miejsce, ale nie cudze.')}${o('full','Pełny ranking','Wszyscy widzą miejsca i pseudonimy wszystkich, także na końcu listy.')}</div>
 <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="doEnable" data-focus>Pokaż ranking</button></div>`,'me');}
function mFull(){return dlg(`<h2 class="h2" id="mf">Pokazać pełny ranking?</h2><p>Każdy student zobaczy miejsca i pseudonimy wszystkich, także osób na końcu listy.</p>
 <div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Zostaw podium</button><button class="btn" data-act="doFull">Pokaż pełny ranking</button></div>`,'mf');}
function mRmT(){const t=S.teachers[S.modal.i];return dlg(`<h2 class="h2" id="mr">Usunąć ${esc(t.name)} z grupy?</h2><p>Straci dostęp do grupy. Nagrody, które przyznał, zostają u studentów.</p><div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Anuluj</button><button class="btn" data-act="doRmT">Usuń z grupy</button></div>`,'mr');}
function notif(){const un=S.notes.filter(n=>n.u).length,row=(n,i)=>{const it=n.item?ITEM[n.item]:{name:n.name,glyph:n.glyph};return `<li><button class="nrow${n.u?' unread':''}" data-act="readN" data-i="${i}">${mini(it.glyph)}<span><b>${esc(n.stu)}</b><span class="it">Zakup: ${esc(it.name)}</span>${gchip(n.g)}</span><time>${n.d?n.d+', ':''}${n.t}</time></button></li>`;};
 return `<div class="pop-ovl" data-act="close"><div class="pop-w np" data-act="noop" role="dialog" aria-label="Powiadomienia"><div class="pop"><div class="n-h"><h2 class="h3">Powiadomienia</h2>${un?`<button class="linkbtn" data-act="readAll">Oznacz wszystkie jako przeczytane</button>`:''}</div>
 ${un?`<p class="n-sec">Nowe (${un})</p><ul style="list-style:none;margin:0;padding:0">${S.notes.map((n,i)=>n.u?row(n,i):'').join('')}</ul>`:'<p class="expl">Nie masz nowych powiadomień.</p>'}
 <p class="n-sec">Wcześniej</p><ul style="list-style:none;margin:0;padding:0">${S.notes.map((n,i)=>n.u?'':row(n,i)).join('')}</ul>
 <div class="pop-f"><button class="btn sec" data-act="hint">Wszystkie zakupy</button></div></div></div></div>`;}
function layer(){const L=app.querySelector('#layer');if(!S.modal&&!S.pop){L.innerHTML='';L.classList.remove('on');return;}L.classList.add('on');
 L.innerHTML=S.pop?notif():{nick:mNick,addT:mAddT,rmT:mRmT,enable:mEnable,full:mFull}[S.modal.m]();const f=L.querySelector('[data-focus]');if(f){f.focus();if(f.setSelectionRange)f.setSelectionRange(f.value.length,f.value.length);}}
/* ---------- shell ---------- */
const ACT={noop(){},theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},hint(){hint('Not part of this screen.');},go(a){S.view=a.dataset.v;S.pop=false;render();},
 close(){S.modal=null;S.pop=false;layer();const b=app.querySelector('[data-act=bell]');if(b)b.setAttribute('aria-expanded','false');},
 vis(){if(S.visible){S.visible=false;render(true);toast(icon('eyeOff')+'Ranking ukryty przed studentami.');}else{S.modal={m:'enable',mode:'podium'};layer();}},pickMode(a){S.modal.mode=a.dataset.v;layer();},doEnable(){S.visible=true;S.mode=S.modal.mode;S.modal=null;render(true);toast(icon('check')+(S.mode==='podium'?'Ranking widoczny: podium i własne miejsce.':'Ranking widoczny w całości.'));},mode(a){if(a.dataset.v==='full'&&S.mode!=='full'){S.modal={m:'full'};layer();return;}S.mode=a.dataset.v;render(true);toast(icon('check')+'Studenci widzą teraz tylko podium i swoje miejsce.');},doFull(){S.mode='full';S.modal=null;render(true);toast(icon('check')+'Ranking widoczny w całości.');},
 nick(){const me=STU.find(s=>s.name===ME);S.modal={m:'nick',v:me.nick};layer();},
 saveNick(){const v=S.modal.v.trim(),taken=STU.some(s=>s.name!==ME&&s.nick.toLowerCase()===v.toLowerCase());
  if(taken){S.modal.err='Ten pseudonim jest już zajęty w tej grupie.';layer();return;}STU.find(s=>s.name===ME).nick=v;S.modal=null;render(true);toast(icon('check')+(v?`Twój pseudonim w tej grupie: ${esc(v)}.`:'Usunięto pseudonim.'));},
 addT(){S.modal={m:'addT',q:''};layer();},
 doAddT(a){const t=POOL.find(p=>p.name===a.dataset.n);S.teachers.push({name:t.name,email:t.email,added:'dziś'});render(true);toast(icon('check')+`Dodano: ${esc(t.name)}.`);},
 rmT(a){S.modal={m:'rmT',i:+a.dataset.i};layer();},doRmT(){const t=S.teachers.splice(S.modal.i,1)[0];S.modal=null;render(true);toast(icon('check')+`Usunięto z grupy: ${esc(t.name)}.`);},
 bell(){S.pop=!S.pop;S.modal=null;layer();},readN(a){S.notes[+a.dataset.i].u=0;S.pop=false;render(true);hint('Would open the purchases list for that group.');},
 readAll(){S.notes.forEach(n=>n.u=0);render(true);S.pop=true;layer();}};
ON('input',e=>{const t=e.target;if(t.dataset.nick!=null){S.modal.v=t.value;if(S.modal.err){S.modal.err=null;layer();}}if(t.dataset.tq!=null){S.modal.q=t.value;app.querySelector('#tres-w').innerHTML=resHtml();}});
DON('keydown',e=>{if(e.key==='Escape'&&(S.modal||S.pop))ACT.close();});

const ROUTES_OF = {rt: 't/ranking', rs: 's/ranking', teachers: 't/teachers'};
['bell', 'readN', 'readAll', 'theme'].forEach(k => delete ACT[k]);
ACT.close = function () { S.modal = null; closeLayer(); };

reg('rk', {
  act: ACT, layer,
  closeLayer() { S.modal = null; S.pop = false; },
  setView(v) { S.view = v; S.modal = null; S.pop = false; },
  page() { setRoute(ROUTES_OF[S.view]); return `<div class="page">${{rt: vRT, rs: vRS, teachers: vTeachers}[S.view]()}</div>`; }
});
})();
