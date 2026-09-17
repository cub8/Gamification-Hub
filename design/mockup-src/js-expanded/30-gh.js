/* ===== module: gh (group index, teacher group home, student group settings) ===== */
(() => {
const ON = (t, f) => on('gh', t, f), DON = (t, f) => ondoc('gh', t, f);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
/*SHARED*/
Object.assign(IC,{x:'<path d="M6 6l12 12M18 6L6 18"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',edit:'<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13 7l4 4"/>',logout:'<path d="M10 4H4v16h6M15 8l4 4-4 4M9 12h10"/>',up:'<path d="M6 15l6-6 6 6"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const glyph=n=>`<svg class="gph" viewBox="0 0 64 64" aria-hidden="true">${GL[n]||''}</svg>`;
const mini=g=>`<span class="card item mc"><span class="card-f"><span class="card-i">${glyph(g)}</span></span></span>`;
const initials=n=>n.split(/\s+/).map(w=>w[0]).join('').slice(0,2).toUpperCase(),hue=n=>[...n].reduce((a,c)=>a+c.charCodeAt(0),0)%5;
const av=n=>`<span class="av sm" data-h="${hue(n)}" aria-hidden="true">${initials(n)}</span>`;
const svgUrl=s=>`url('data:image/svg+xml;charset=utf-8,${encodeURIComponent(s)}')`;
const ART={rabbits:"url('__RABBITS__')",waves:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#0E4F5C"/><g fill="none" stroke-width="5"><path d="M-10 40q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#2F9DA3"/><path d="M-10 60q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#5CCFC6"/></g></svg>'),
 flow:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#17492F"/><g fill="none" stroke="#7CD6A0" stroke-width="4"><path d="M14 36h32v18H14zM114 36h32v18h-32zM80 22l16 23-16 23-16-23zM46 45h18M96 45h18"/></g></svg>'),
 tables:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#35245E"/><g fill="none" stroke="#A58EE6" stroke-width="4"><path d="M18 18h50v54H18zM18 36h50M18 54h50M42 18v54M92 26h50v38H92zM92 44h50M116 26v38M68 45h24"/></g></svg>')};
const GS_T=[{id:'kk',name:'Kosmiczne króliki',art:'rabbits',role:'own',students:12,meta:'3 nowe zakupy'},{name:'Wstęp do algorytmiki szkolnej',art:'flow',role:'own',students:24,meta:'1 nowy zakup'},{name:'Relacyjne bazy danych',art:'tables',role:'own',students:31,meta:'Brak nowych zakupów'},
 {name:'Inżynieria oprogramowania',art:null,role:'own',students:27,meta:'Brak grafiki grupy'},{name:'Atlantyda',art:'waves',role:'sup',students:18,meta:'Właściciel: Janusz Nowakowski'},{name:'Dydaktyka cyfrowa (szkolenie)',art:null,role:'lrn',students:40,meta:'Masz 14 Punktów'}];
const RL={own:['r-own','Prowadzisz'],sup:['r-sup','Wspierasz'],lrn:['r-lrn','Uczysz się']};
const TABS=[['all','Wszystkie',()=>true],['own','Moje',g=>g.role==='own'],['lrn','Uczę się',g=>g.role==='lrn'],['teach','Nauczam',g=>g.role!=='lrn']];
const NICKS=['Kapitan Uszatek','Nova','Orbita','Meteor','Mat-7','Gwiazdka','Luna','Zebra z Kosmosu','Kosmo','Neptun'];
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',view:'index',tab:'all',q:'',modal:null,get nick(){return DB.me().nick;},set nick(v){DB.me().nick=v;},nickIn:DB.me().nick,nickErr:null};
const mono=n=>n.split(/\s+/).filter(w=>w.length>2).slice(0,2).map(w=>w[0]).join('').toUpperCase();
/* ---------- index ---------- */
function vIndex(){const f=TABS.find(t=>t[0]===S.tab)[2],q=S.q.trim().toLowerCase(),list=GS().filter(f).filter(g=>!q||g.name.toLowerCase().includes(q));
 return `<section class="panel phead"><div class="phead-t"><h1>Grupy</h1><p class="lead">Grupy, które prowadzisz, wspierasz albo w których się uczysz.</p></div><div class="rowb"><button class="btn sec" data-act="join">${icon('plus')}Dołącz do grupy</button>${G.persona==='teacher'?`<button class="btn" data-act="nav" data-to="t/new-group">${icon('plus')}Utwórz grupę</button>`:''}</div></section>
 <div class="gtabs" role="tablist" aria-label="Filtr grup">${TABS.map(([k,l,fn])=>`<button class="gt2" role="tab" aria-selected="${S.tab===k}" data-act="tab" data-v="${k}">${l}<span class="n">${GS().filter(fn).length}</span></button>`).join('')}</div>
 <div class="ixbar"><label class="search">${icon('search')}<input type="search" data-q value="${esc(S.q)}" placeholder="Szukaj grupy" aria-label="Szukaj grupy"></label></div>
 ${list.length?`<div class="ixgrid">${list.map(g=>`<article class="card neutral ixc full" data-act="openGroup" data-g="${g.id||''}"><div class="card-f"><div class="card-i"><div class="art art-img${g.art?'':' nart'}"${g.art?` style="background-image:${ART[g.art]}"`:''} aria-hidden="true">${g.art?'':mono(g.name)}</div><div class="card-top"><h2 class="card-name" style="font-size:19px">${esc(g.name)}</h2></div>
 <span class="tag ${RL[g.role][0]} roletag">${RL[g.role][1]}</span><p class="ixmeta"><span>${g.students} ${pl(g.students,'student','studentów','studentów')}</span><span>${esc(g.meta)}</span></p></div></div></article>`).join('')}</div>`
 :`<section class="panel gm" style="margin-top:18px;text-align:center"><h2 class="h2">${S.q?`Brak grup o nazwie „${esc(S.q)}”`:S.tab==='lrn'?'Nie uczysz się w żadnej grupie':'Brak grup w tej zakładce'}</h2><p class="lead" style="margin:8px auto 0">${S.tab==='lrn'?'Masz kod od prowadzącego? Dołącz do grupy jako uczestnik.':'Zmień zakładkę albo wyczyść wyszukiwanie.'}</p></section>`}`;}
/* ---------- teacher home ---------- */
function vHome(){const P=[['Sebastian Alejandro','popr','dziś, 10:21'],['Barbara Kowalewska','min5','dziś, 09:58'],['Adrian Kowalski','kons','wczoraj, 17:10'],['Adam Pawłowski','oneup','10.06']];
 const top=(t,rows,vis)=>`<div class="sheet2"><div><b>${t}</b><button class="linkbtn" data-act="nav" data-to="t/sheets">Otwórz</button></div><ol class="top3">${rows.map(([n,s],i)=>`<li><span class="pos p${i+1}">${i+1}</span>${esc(n)}<span class="sc">+${s}</span></li>`).join('')}</ol><p class="small" style="margin-top:6px">${vis}</p></div>`;
 return `<section class="card neutral full"><div class="card-f"><div class="card-i hero"><div class="art art-img" style="background-image:${ART.rabbits}" aria-hidden="true"></div><div class="hero-b"><h1>Kosmiczne króliki</h1><p class="lore-t">Galaktyka jest wielka, ale nasze uszy są większe! Dołącz do pionierów, którzy zamienili nory na stacje orbitalne.</p>
 <div class="rowb"><button class="btn" data-act="nav" data-to="t/invites">${icon('qr')}Pokaż kod dla studentów</button><button class="btn sec" data-act="nav" data-to="t/sheets">${icon('grid')}Utwórz arkusz</button><button class="btn sec" data-act="nav" data-to="t/group-settings">${icon('settings')}Ustawienia grupy</button></div></div></div></div></section>
 <section class="panel kpis"><dl style="display:contents"><div class="kpi"><dt>Studenci</dt><dd>12</dd></div><div class="kpi"><dt>Zakupy w tym tygodniu</dt><dd>4<small>za 95</small></dd></div><div class="kpi"><dt>Nagrody w tym tygodniu</dt><dd>46</dd></div><div class="kpi"><dt>Ranking</dt><dd style="font-size:17px">Podium i własne miejsce</dd></div></dl></section>
 <div class="hgrid"><section class="panel hp"><h2 class="h2">Ostatnie zakupy</h2><ul class="plist">${P.map(([s,id,t])=>{const it=ITEM[id];return `<li class="prow" style="grid-template-columns:52px minmax(0,1fr) auto 90px">${mini(it.glyph)}<span class="p-main"><b>${esc(it.name)}</b><span>${esc(s)}</span></span><span class="cost sm"><b>${it.cost}</b></span><span class="p-time">${t}</span></li>`;}).join('')}</ul><button class="linkbtn" style="margin:10px 0 4px" data-act="nav" data-to="t/purchases">Wszystkie zakupy w grupie</button></section>
 <div class="hcol"><section class="panel hp"><h2 class="h2">Wymaga uwagi</h2><ul class="att">
 <li><span class="lv z">${icon('heart')}</span><span><b>Mateusz Lewandowski ma 0 żyć</b><small>Kupi tylko przedmioty dostępne przy 0 życiach.</small></span><button class="linkbtn" data-act="nav" data-to="t/student" data-i="8">Otwórz</button></li>
 <li>${icon('up')}<span><b>${esc(DB.me().name)}: ${Math.max(0,40-DB.me().tot)} do awansu</b><small>${DB.me().tot} z 40 do rangi Kosmiczny Królik.</small></span><button class="linkbtn" data-act="nav" data-to="t/student" data-i="3">Otwórz</button></li>
 <li>${icon('grid')}<span><b>Laboratoria 5 w trakcie</b><small>Przyznano 21 nagród, 9 kolumn bez ocen.</small></span><button class="btn sm" data-act="nav" data-to="t/grade">Oceń</button></li></ul></section>
 <section class="panel hp"><h2 class="h2">Ostatnie arkusze</h2>${top('Laboratoria 4',[['Adam Pawłowski',11],['Barbara Kowalewska',8],['Sebastian Alejandro',6]],'Studenci widzą to podium pod pseudonimami.')}${top('Laboratoria 3',[['Julia Wójcik',12],['Adam Pawłowski',10],['Jakub Szymański',9]],'Studenci widzą to podium pod pseudonimami.')}</section></div></div>`;}
/* ---------- student group settings ---------- */
function vSset(){return `<section class="panel phead" style="display:block"><p class="crumbs"><a href="#/s/home" data-act="nav" data-to="s/home">Kosmiczne króliki</a>${icon('chevRight')}<span>Ustawienia w grupie</span></p><h1>Ustawienia w grupie</h1><p class="lead">Te ustawienia dotyczą tylko grupy Kosmiczne króliki.</p></section>
 <section class="panel setp2"><h2 class="h3">Pseudonim</h2><p class="hint" style="margin-top:4px">Widoczny w rankingu tylko w tej grupie. W innych grupach możesz mieć inny.</p>
 <div class="fld"><label for="f-nick">Twój pseudonim</label><div class="row2b" style="display:flex;gap:10px;align-items:flex-start;flex-wrap:wrap"><div class="inp${S.nickErr?' bad':''}" style="flex:1;min-width:220px"><input id="f-nick" data-nick="set" value="${esc(S.nickIn)}" maxlength="24" autocomplete="off"${S.nickErr?' aria-invalid="true" aria-describedby="e-nick"':''}></div><button class="btn" data-act="saveNick"${S.nickIn.trim()===S.nick?' disabled':''}>Zapisz</button></div>${S.nickErr?`<p class="err" id="e-nick">${icon('alert')}${S.nickErr}</p>`:''}<span class="hint">Do 24 znaków.</span></div></section>
 <section class="panel setp2"><h2 class="h3">Co widzi prowadzący</h2><p class="hint" style="margin-top:4px">Pozostali studenci widzą tylko Twój pseudonim, i to tylko w rankingu.</p>
 <ul class="seeing"><li><span>Imię i nazwisko</span><b>${esc(DB.me().name)}</b></li><li><span>E-mail</span><b>${esc(DB.me().email)}</b></li><li><span>Numer indeksu</span><b>${esc(DB.me().index)}</b></li><li><span>Waluta, odznaki, przedmioty i historia</span><b>Tak</b></li></ul></section>
 <section class="panel danger"><h2 class="h3">Opuść grupę</h2><p class="small" style="margin-top:6px">Stracisz dostęp do grupy. Żeby wrócić, potrzebujesz nowego kodu od prowadzącego.</p><button class="btn sec" style="margin-top:12px" data-act="leave">${icon('logout')}Opuść grupę</button></section>`;}
/* ---------- modals ---------- */
const dlg=(h,id)=>`<div class="ovl" data-act="close"><div class="dlg" role="dialog" aria-modal="true" aria-labelledby="${id}" data-act="noop"><div class="dlg-in"><span class="grab"></span>${h}</div></div></div>`;
function mLeave(){return dlg(`<h2 class="h2" id="ml">Opuścić grupę Kosmiczne króliki?</h2><p>Stracisz dostęp do sklepu, rankingu i swojej historii w tej grupie: ${DB.me().bal} ${curA(DB.me().bal)}, ${DB.me().badges.length} ${pl(DB.me().badges.length,'odznaki','odznak','odznak')} i ${DB.me().items.length} ${pl(DB.me().items.length,'przedmiotu','przedmiotów','przedmiotów')}.</p><p class="small">Jeśli wrócisz do tej grupy z nowym kodem od prowadzącego, wszystko wróci: waluta, odznaki i przedmioty. Nic nie przepada.</p>
 <div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Zostań w grupie</button><button class="btn" data-act="doLeave">Opuść grupę</button></div>`,'ml');}
function mJoin(){const M=S.modal;return dlg(`<p class="small" style="margin-bottom:4px">Krok 2 z 2</p><h2 class="h2" id="mj">Dołączasz do grupy Kosmiczne króliki</h2><p>Wybierz pseudonim. Inni studenci zobaczą go w rankingu, prowadzący zobaczy też Twoje imię i nazwisko.</p>
 <div class="fld"><label for="j-nick">Pseudonim w tej grupie</label><div class="inp${M.err?' bad':''}"><input id="j-nick" data-nick="join" value="${esc(M.v)}" maxlength="24" autocomplete="off" data-focus${M.err?' aria-invalid="true" aria-describedby="e-jn"':''}></div>${M.err?`<p class="err" id="e-jn">${icon('alert')}${M.err}</p>`:''}<span class="hint">Możesz go później zmienić w ustawieniach grupy.</span></div>
 <p class="lbl" style="margin-top:14px">Propozycje</p><div class="sugg">${['Kosmiczny Kadet','Uszaty Pilot','Marchewkowy Zwiadowca'].map(s=>`<button class="fchip" data-act="sugg" data-v="${s}">${s}</button>`).join('')}</div>
 <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="doJoin">Dołącz do grupy</button></div>`,'mj');}
function layer(){const L=app.querySelector('#layer');if(!S.modal){L.innerHTML='';L.classList.remove('on');return;}L.classList.add('on');L.innerHTML={leave:mLeave,join:mJoin}[S.modal.m]();const f=L.querySelector('[data-focus]');if(f){f.focus();if(f.setSelectionRange)f.setSelectionRange(f.value.length,f.value.length);}}
const nickErr=v=>!v.trim()?'Podaj pseudonim.':NICKS.some(n=>n.toLowerCase()===v.trim().toLowerCase())?'Ten pseudonim jest już zajęty w tej grupie.':null;
/* ---------- shell ---------- */
const teacher=()=>S.view!=='sset',inG=()=>S.view!=='index';
const ACT={noop(){},theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},hint(){hint('Opens another screen (built separately).');},go(a){S.view=a.dataset.v;S.modal=null;render();},
 tab(a){S.tab=a.dataset.v;render(true);},close(){S.modal=null;layer();},leave(){S.modal={m:'leave'};layer();},doLeave(){S.modal=null;layer();toast(icon('check')+'Opuszczono grupę (makieta).');},
 join(){S.modal={m:'join',v:'',err:null};layer();},sugg(a){S.modal.v=a.dataset.v;S.modal.err=null;layer();},
 doJoin(){const e=nickErr(S.modal.v);if(e){S.modal.err=e;layer();return;}const v=S.modal.v.trim();S.modal=null;layer();toast(icon('check')+`Dołączono do grupy Kosmiczne króliki jako ${esc(v)}.`);},
 saveNick(){const v=S.nickIn.trim(),e=nickErr(v);if(e){S.nickErr=e;render(true);app.querySelector('#f-nick').focus();return;}S.nick=v;S.nickIn=v;S.nickErr=null;render(true);toast(icon('check')+`Twój pseudonim w tej grupie: ${esc(v)}.`);}};
ON('input',e=>{const t=e.target;
 if(t.dataset.q!=null){S.q=t.value;render(true);const i=app.querySelector('[data-q]');i.focus();i.setSelectionRange(i.value.length,i.value.length);}
 if(t.dataset.nick==='set'){S.nickIn=t.value;const b=app.querySelector('[data-act=saveNick]');if(b)b.disabled=t.value.trim()===S.nick;if(S.nickErr){S.nickErr=null;t.parentNode.classList.remove('bad');const m=app.querySelector('#e-nick');if(m)m.remove();}}
 if(t.dataset.nick==='join'){S.modal.v=t.value;if(S.modal.err){S.modal.err=null;t.parentNode.classList.remove('bad');const m=app.querySelector('#e-jn');if(m)m.remove();}}});
DON('keydown',e=>{if(e.key==='Escape'&&S.modal)ACT.close();});

const GS = () => G.persona === 'teacher' ? GS_T
  : DB.myGroups.map(g => ({id: g.id, name: g.name, art: g.art, role: 'lrn', students: 12,
      meta: `${g.bal} ${pl(g.bal, ...g.c)}, ranga ${g.rank}`}));
const ROUTES_OF = {index: () => G.persona === 'teacher' ? 't/groups' : 's/groups', home: () => 't/home', sset: () => 's/group-settings'};
['theme', 'join'].forEach(k => delete ACT[k]);
ACT.go = a => nav(a.dataset.to || (a.dataset.v === 'home' ? 't/home' : a.dataset.v === 'sset' ? 's/group-settings' : G.persona === 'teacher' ? 't/groups' : 's/groups'));
ACT.openGroup = a => (a.dataset.g === 'kk' ? nav(G.persona === 'teacher' ? 't/home' : 's/home') : CORE_ACT.stub(a));

reg('gh', {
  act: ACT, layer,
  closeLayer() { S.modal = null; },
  setView(v) { S.modal = null; S.view = v; S.q = ''; if (v === 'sset') { S.nickIn = DB.me().nick; S.nickErr = null; } },
  page() { setRoute(ROUTES_OF[S.view]()); return `<div class="page">${{index: vIndex, home: vHome, sset: vSset}[S.view]()}</div>`; }
});
})();
