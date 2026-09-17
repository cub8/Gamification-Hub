/* ===== module: isg (invites, group settings, student start, from t/isg.html) ===== */
(() => {
const ON = (t, f) => on('isg', t, f), DON = (t, f) => ondoc('isg', t, f);
const MY = DB.myGroups;
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
/*SHARED*/
Object.assign(IC,{minus:'<path d="M5 12h14"/>',x:'<path d="M6 6l12 12M18 6L6 18"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',edit:'<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13 7l4 4"/>',trash:'<path d="M4 6h16M9 6V3h6v3M6 6l1 15h10l1-15"/>',eye:'<path d="M2.5 12S6 6 12 6s9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6z"/><path d="M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const tok=(k,s)=>`<span class="tok" style="--s:${s}px"><span><svg viewBox="0 0 24 24">${CI[k]}</svg></span></span>`;
const bar=(v,m)=>`<div class="bar"><i style="--p:${m?Math.round(Math.min(v,m)/m*100):0}%"></i></div>`;
const svgUrl=s=>`url('data:image/svg+xml;charset=utf-8,${encodeURIComponent(s)}')`;
const ART={rabbits:"url('__RABBITS__')",castle:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#2B2440"/><circle cx="126" cy="22" r="9" fill="#F2E3B3"/><path d="M34 90V46h8v-6h6v6h8V30h6v-6h6v6h6v16h8v-6h6v6h8v44z" fill="#6E6480"/></svg>'),
 flow:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#17492F"/><g fill="none" stroke="#7CD6A0" stroke-width="4"><path d="M14 36h32v18H14zM114 36h32v18h-32zM80 22l16 23-16 23-16-23zM46 45h18M96 45h18"/></g></svg>'),
 tables:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#35245E"/><g fill="none" stroke="#A58EE6" stroke-width="4"><path d="M18 18h50v54H18zM18 36h50M18 54h50M42 18v54M92 26h50v38H92zM92 44h50M116 26v38M68 45h24"/></g></svg>'),
 waves:svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#0E4F5C"/><path d="M-10 50q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#5CCFC6" stroke-width="6" fill="none"/></svg>')};
const NOW=new Date('2026-09-11T12:00');
const fmt=iso=>{const d=new Date(iso);return `${String(d.getDate()).padStart(2,'0')}.${String(d.getMonth()+1).padStart(2,'0')}, ${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`;};
const ALPH='ABCDEFGHJKMNPQRSTUVWXYZ23456789',newCode=()=>Array.from({length:6},()=>ALPH[Math.floor(Math.random()*ALPH.length)]).join('');
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',view:'inv',modal:null,err:{},
 get inv(){return DB.invites;},set inv(v){DB.invites=v;}};
const status=v=>v.exp&&new Date(v.exp)<NOW?'Wygasło':v.max&&v.uses>=v.max?'Wyczerpane':'Aktywne';
const usesTxt=v=>v.max?`${v.uses} z ${v.max}`:`${v.uses}, bez limitu`;
/* ---------- invites ---------- */
function ivRow(v,i){const st=status(v),on=st==='Aktywne';return `<div class="iv${v.fresh?' fresh':''}"><span class="cd">${v.code}</span><span><span class="stt ${on?'on':'off'}">${st}</span></span>
 <span class="u">Użycia: ${usesTxt(v)}${v.max?bar(v.uses,v.max):''}</span><span class="e">${v.exp?(on?'Wygasa ':'Wygasło ')+fmt(v.exp):'Bez daty ważności'}</span>
 <span class="acts">${on?`<button class="btn sm" data-act="show" data-i="${i}">${icon('qr')}Pokaż</button>`:''}<button class="iconbtn" data-act="edit" data-i="${i}" aria-label="Edytuj zaproszenie ${v.code}" title="Edytuj">${icon('edit')}</button><button class="iconbtn" data-act="del" data-i="${i}" aria-label="Usuń zaproszenie ${v.code}" title="Usuń">${icon('trash')}</button></span></div>`;}
function vInv(){const all=S.inv.map((v,i)=>[v,i]),act=all.filter(([v])=>status(v)==='Aktywne'),ina=all.filter(([v])=>status(v)!=='Aktywne');
 return `<section class="panel phead"><div class="phead-t"><h1>Zaproszenia</h1><p class="lead">Kod ma 6 znaków bez mylących liter (bez O, 0, I, 1 i L). Studenci wpisują go w „Dołącz do grupy” albo skanują kod QR.</p></div><button class="btn" data-act="new">${icon('plus')}Nowe zaproszenie</button></section>
 <section class="panel ivl"><div class="iv h"><span>Kod</span><span>Status</span><span>Użycia</span><span>Ważność</span><span></span></div>${act.length?act.map(([v,i])=>ivRow(v,i)).join(''):'<p class="expl">Brak aktywnych zaproszeń. Utwórz nowe, żeby studenci mogli dołączyć.</p>'}</section>
 ${ina.length?`<details class="inact"><summary>Nieaktywne (${ina.length}): wygasłe i wyczerpane</summary><section class="panel ivl" style="margin-top:6px">${ina.map(([v,i])=>ivRow(v,i)).join('')}</section></details>`:''}`;}
function sumTxt(M){return 'Kod będzie działał '+(M.limOn?`dla ${M.max||0} ${pl(+M.max||0,'osoby','osób','osób')}`:'bez limitu osób')+' '+(M.expOn?`do ${fmt(M.date+'T'+M.time)}`:'i bez daty ważności')+'.';}
function mForm(){const M=S.modal,ed=M.i!=null,v=ed?S.inv[M.i]:null;
 return `<h2 class="h2" id="mt">${ed?`Edytuj zaproszenie ${v.code}`:'Nowe zaproszenie'}</h2><p>${ed?'Kod zostaje ten sam. Zmieniasz tylko ograniczenia.':'Oba ograniczenia są opcjonalne.'}</p>
 ${ed?'':`<div class="presets"><button class="fchip" data-act="preset" data-v="today">Na dzisiejsze zajęcia</button><button class="fchip" data-act="preset" data-v="none">Bez ograniczeń</button></div>`}
 <div class="lim"><div class="swrow" style="margin-top:0"><button class="sw" role="switch" aria-checked="${M.limOn}" data-act="tg" data-k="limOn" aria-labelledby="l-lim"><i></i></button><span><b id="l-lim">Limit użyć</b><span class="hint">Kod przestanie działać, gdy dołączy tyle osób.</span></span></div>
 ${M.limOn?`<div class="row2"><div class="inp num${S.err.max?' bad':''}"><input type="number" min="1" data-m="max" value="${M.max}" aria-label="Limit użyć"${S.err.max?' aria-invalid="true" aria-describedby="e-max"':''}></div><span class="k">${pl(+M.max||0,'osoba','osoby','osób')}</span></div>${S.err.max?`<p class="err" id="e-max">${icon('alert')}${S.err.max}</p>`:''}`:''}</div>
 <div class="lim"><div class="swrow" style="margin-top:0"><button class="sw" role="switch" aria-checked="${M.expOn}" data-act="tg" data-k="expOn" aria-labelledby="l-exp"><i></i></button><span><b id="l-exp">Data ważności</b><span class="hint">Po tej chwili kod przestanie działać.</span></span></div>
 ${M.expOn?`<div class="row2"><div class="inp${S.err.exp?' bad':''}"><input type="date" data-m="date" value="${M.date}" aria-label="Data"></div><div class="inp"><input type="time" data-m="time" value="${M.time}" aria-label="Godzina"></div></div>${S.err.exp?`<p class="err">${icon('alert')}${S.err.exp}</p>`:''}`:''}</div>
 <p class="expl" id="isum">${sumTxt(M)}</p>
 <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="saveInv">${ed?'Zapisz zmiany':'Utwórz zaproszenie'}</button></div>`;}
function qr(seed){let h=27,d='';const rnd=()=>(seed=(seed*9301+49297)%233280)/233280,f=(x,y)=>{d+=`M${x} ${y}h7v7h-7zM${x+1} ${y+1}v5h5v-5zM${x+2} ${y+2}h3v3h-3z`;};
 for(let y=0;y<h;y++)for(let x=0;x<h;x++){if(!((x<8&&y<8)||(x>h-9&&y<8)||(x<8&&y>h-9))&&rnd()>.52)d+=`M${x} ${y}h1v1h-1z`;}f(0,0);f(h-7,0);f(0,h-7);return `<svg class="qr" viewBox="0 0 ${h} ${h}" role="img" aria-label="Kod QR (podgląd w makiecie)"><path d="${d}" fill="#111" fill-rule="evenodd"/></svg>`;}
function mShow(){const v=S.inv[S.modal.i];return `<h2 class="h2" id="mt">Dołącz do grupy Kosmiczne króliki</h2><p>Wpisz kod w aplikacji („Dołącz do grupy”) albo zeskanuj kod QR.</p><div class="qrbox">${qr([...v.code].reduce((a,c)=>a+c.charCodeAt(0),0))}<div><div class="code-big" aria-label="Kod: ${v.code.split('').join(' ')}">${v.code}</div><p class="small" style="margin-top:12px">Użycia: ${usesTxt(v)}. ${v.exp?'Wygasa '+fmt(v.exp)+'.':'Bez daty ważności.'}</p></div></div><div class="dlg-b"><button class="btn" data-act="close" data-focus>Zamknij</button></div>`;}
function mDel(){const v=S.inv[S.modal.i];return `<h2 class="h2" id="mt">Usunąć zaproszenie ${v.code}?</h2><p>Kod przestanie działać od razu. ${v.uses?`${v.uses} ${pl(v.uses,'osoba, która dołączyła','osoby, które dołączyły','osób, które dołączyły')} z tym kodem, zostaje w grupie.`:''}</p><div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Anuluj</button><button class="btn" data-act="doDel">Usuń zaproszenie</button></div>`;}
/* ---------- group settings ---------- */
const F0={name:'Kosmiczne króliki',story:'Galaktyka jest wielka, ale nasze uszy są większe! Dołącz do pionierów, którzy zamienili nory na stacje orbitalne.',art:'rabbits',n1:'Złota Marchewka',n2:'Złote Marchewki',n5:'Złotych Marchewek',icon:'carrot',lives:3};
function vSet(){const f=S.f,d=JSON.stringify(f)!==S.orig,inp=(k,ph)=>`<div class="inp${S.err[k]?' bad':''}"><input id="s-${k}" data-s="${k}" value="${esc(f[k])}" placeholder="${ph}"></div>`;
 return `<section class="panel phead" style="display:block"><h1>Ustawienia grupy</h1><p class="lead">Zmienią je wszyscy prowadzący tę grupę. Tylko właściciel może usunąć grupę. Ranking ustawiasz w zakładce Ranking.</p></section>
 <section class="panel setp"><div class="fsec" style="margin:0;padding:0;border:0"><h2 class="h3">Grupa i opowieść</h2>
 <div class="fld"><label for="s-name">Nazwa grupy</label>${inp('name','Nazwa grupy')}${S.err.name?`<p class="err">${icon('alert')}${S.err.name}</p>`:''}</div>
 <div class="fld"><label for="s-story">Opowieść</label><div class="inp"><textarea id="s-story" data-s="story" rows="3">${esc(f.story)}</textarea></div></div>
 <div class="fld"><p class="lbl">Grafika grupy</p><div class="pz-grid" role="radiogroup" aria-label="Grafika">${Object.keys(ART).map(k=>`<button class="pz" role="radio" aria-checked="${f.art===k}" data-act="art" data-v="${k}" aria-label="Grafika ${k}"><i style="background-image:${ART[k]}"></i></button>`).join('')}<label class="btn sec sm" style="align-self:center">${icon('plus')}Wgraj własną<input type="file" accept="image/*" class="sr"></label></div></div></div>
 <div class="fsec"><h2 class="h3">Waluta</h2><p class="hint">Nowa nazwa pojawi się wszędzie, także w historii studentów.</p>
 <div class="row3"><div class="fld"><label for="s-n1">Przy liczbie 1</label>${inp('n1','')}</div><div class="fld"><label for="s-n2">Przy 2, 3, 4</label>${inp('n2','')}</div><div class="fld"><label for="s-n5">Przy 5 i więcej</label>${inp('n5','')}</div></div>
 <div class="fld"><p class="lbl">Ikona</p><div class="pz-grid">${['carrot','pearl','bit'].map(k=>`<button class="pz cur" role="radio" aria-checked="${f.icon===k}" data-act="icon" data-v="${k}" aria-label="Ikona ${k}"><i><svg viewBox="0 0 24 24">${CI[k]}</svg></i></button>`).join('')}</div></div></div>
 <div class="fsec"><h2 class="h3">Życia</h2><div class="fld"><p class="lbl" id="l-lv">Życia na start</p><div class="nstep" role="group" aria-labelledby="l-lv"><button data-act="lv" data-d="-1" aria-label="Mniej">${icon('minus')}</button><output>${f.lives}</output><button data-act="lv" data-d="1" aria-label="Więcej">${icon('plus')}</button></div><span class="hint">Dotyczy tylko studentów, którzy dołączą od teraz. Obecnym zmieniasz życia na liście studentów.</span></div></div></section>
 <section class="panel danger"><h2 class="h3">Usuń grupę</h2><p class="small" style="margin-top:6px">Usunięcie zabiera wszystkim dostęp do grupy, jej sklepu, rankingu i historii. Tego nie da się cofnąć.</p><button class="btn sec" style="margin-top:12px" data-act="delG">${icon('trash')}Usuń grupę</button></section>
 <div style="margin:22px 0 14px"><div class="panel wbar"><span class="k">${d?'Niezapisane zmiany':'Brak zmian'}</span><span class="sp"></span>${d?'<button class="linkbtn" data-act="discard">Odrzuć zmiany</button>':''}<button class="btn" data-act="saveSet"${d?'':' disabled'}>Zapisz zmiany</button></div></div>`;}
function mDelG(){const ok=(S.modal.v||'').trim()===JSON.parse(S.orig).name;return `<h2 class="h2" id="mt">Usunąć grupę na zawsze?</h2><p>12 studentów i 2 nauczycieli straci dostęp. Historia, przedmioty i ranking znikną.</p>
 <div class="fld"><label for="g-conf">Wpisz nazwę grupy, żeby potwierdzić: <b>${esc(JSON.parse(S.orig).name)}</b></label><div class="inp"><input id="g-conf" data-g value="${esc(S.modal.v||'')}" autocomplete="off" data-focus></div></div>
 <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="doDelG"${ok?'':' disabled'}>Usuń grupę</button></div>`;}
/* ---------- student start ---------- */
function vStart(){const hearts=n=>`<span class="lv${n?'':' z'}">${icon('heart')}</span>${n}`;
 return `<section class="panel phead"><div class="phead-t"><h1>Cześć, Sebastian</h1><p class="lead">Należysz do ${MY.length} ${pl(MY.length,'grupy','grup','grup')}. Waluta, rangi i odznaki są osobne w każdej z nich.</p></div></section>
 <div class="sgrid">${MY.map(g=>`<article class="card neutral gcard full"><div class="card-f"><div class="card-i"><div class="art art-img" style="background-image:${ART[g.art]}"></div><div class="card-top"><h2 class="card-name" style="font-size:19px">${esc(g.name)}</h2></div>
 ${g.fresh?`<p class="expl" style="margin:8px 14px 0">Dopiero zaczynasz. Pierwsze ${g.c[1]} zdobędziesz na zajęciach.</p>`:''}
 <dl class="gstat"><div><dt>Do wydania</dt><dd>${tok(g.cur,24)}${g.bal}<small>${pl(g.bal,...g.c)}</small></dd></div><div><dt>Życia</dt><dd>${hearts(g.lives)}</dd></div>
 <div class="full2"><dt>Ranga: <b style="color:var(--ink)">${g.rank}</b></dt><dd style="font-size:13px;font-weight:560;color:var(--ink-2)">${g.tot} z ${g.next[1]} do rangi ${g.next[0]}</dd>${bar(g.tot,g.next[1])}</div><div><dt>Odznaki</dt><dd>${g.b[0]}<small>z ${g.b[1]}</small></dd></div></dl>
 <div class="card-foot"><button class="btn" data-act="openGroup" data-g="${g.id}" data-to="s/home">Otwórz grupę</button><button class="btn sec" data-act="openGroup" data-g="${g.id}" data-to="s/shop">${icon('bag')}Sklep</button></div></div></div></article>`).join('')}
 <div class="panel joinc"><h2 class="h3">Masz kod od prowadzącego?</h2><p class="small">Kod ma 6 znaków. Możesz też zeskanować kod QR aparatem telefonu.</p><button class="btn sec" data-act="join">${icon('plus')}Dołącz do grupy</button></div></div>
 <section class="panel feed"><h2 class="h2">Ostatnio we wszystkich grupach</h2><ul class="led">${[['earn','+3','Student zjawił się na zajęciach zdalnych','Kosmiczne króliki, dziś 10:20'],['earn','+2','Poprawny algorytm sortowania','Wstęp do algorytmiki szkolnej, wczoraj'],['spend','−15','Zakup: Poprawa wejściówki','Kosmiczne króliki, dziś 10:21'],['corr','','Dołączono do grupy Relacyjne bazy danych','dziś 09:05']].map(([t,a,x,w])=>`<li class="led-r"><span class="led-m ${t} oct" style="--c:3px"></span><span class="led-t">${x}<small>${w}</small></span><span class="led-a ${t}">${a}</span></li>`).join('')}</ul></section>`;}
/* ---------- shell ---------- */
const stu=()=>S.view==='start';
function layer(){const L=app.querySelector('#layer');if(!S.modal){L.innerHTML='';L.classList.remove('on');return;}L.classList.add('on');
 const M=S.modal,h={form:mForm,show:mShow,del:mDel,delG:mDelG}[M.m]();L.innerHTML=`<div class="ovl" data-act="close"><div class="dlg${M.m==='show'?' dlg-code':''}" role="dialog" aria-modal="true" aria-labelledby="mt" data-act="noop"><div class="dlg-in"><span class="grab"></span>${h}</div></div></div>`;
 const f=L.querySelector('[data-focus]');if(f)f.focus();}
function formFrom(v){const d=v&&v.exp?new Date(v.exp):null;return {m:'form',limOn:!!(v&&v.max),max:v&&v.max||30,expOn:!!d,date:d?v.exp.slice(0,10):'2026-09-11',time:d?v.exp.slice(11,16):'23:59'};}
const ACT={noop(){},theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},hint(){hint('Not part of this screen.');},go(a){S.view=a.dataset.v;S.modal=null;render();},
 close(){S.modal=null;S.err={};layer();},new(){S.err={};S.modal=formFrom(null);layer();},edit(a){S.err={};S.modal={...formFrom(S.inv[+a.dataset.i]),i:+a.dataset.i};layer();},
 show(a){S.modal={m:'show',i:+a.dataset.i};layer();},del(a){S.modal={m:'del',i:+a.dataset.i};layer();},doDel(){const v=S.inv.splice(S.modal.i,1)[0];S.modal=null;render(true);toast(icon('check')+`Usunięto zaproszenie ${v.code}.`);},
 tg(a){S.modal[a.dataset.k]=!S.modal[a.dataset.k];S.err={};layer();},
 preset(a){Object.assign(S.modal,a.dataset.v==='today'?{limOn:false,expOn:true,date:'2026-09-11',time:'23:59'}:{limOn:false,expOn:false});S.err={};layer();},
 saveInv(){const M=S.modal,ed=M.i!=null,v=ed?S.inv[M.i]:null;S.err={};
  if(M.limOn&&!(+M.max>=1))S.err.max='Limit musi wynosić co najmniej 1.';else if(M.limOn&&ed&&+M.max<v.uses)S.err.max=`Z tego kodu skorzystało już ${v.uses} ${pl(v.uses,'osoba','osoby','osób')}. Limit nie może być mniejszy.`;
  if(M.expOn&&new Date(M.date+'T'+M.time)<NOW)S.err.exp='Ta data już minęła. Wybierz późniejszą.';if(Object.keys(S.err).length){layer();return;}
  const data={max:M.limOn?+M.max:null,exp:M.expOn?M.date+'T'+M.time:null};
  if(ed){Object.assign(v,data);S.modal=null;render(true);toast(icon('check')+`Zapisano zaproszenie ${v.code}.`);}else{const c=newCode();S.inv.forEach(x=>x.fresh=0);S.inv.unshift({code:c,uses:0,...data,fresh:1});S.modal=null;render(true);toast(icon('check')+`Utworzono kod ${c}. Kliknij „Pokaż”, żeby wyświetlić go studentom.`);}},
 art(a){S.f.art=a.dataset.v;render(true);},icon(a){S.f.icon=a.dataset.v;render(true);},lv(a){S.f.lives=Math.max(0,Math.min(10,S.f.lives+ +a.dataset.d));render(true);},
 discard(){S.f=JSON.parse(S.orig);S.err={};render(true);},saveSet(){if(!S.f.name.trim()){S.err.name='Podaj nazwę grupy.';render(true);return;}S.err={};S.orig=JSON.stringify(S.f);render(true);toast(icon('check')+'Zapisano ustawienia grupy.');},
 delG(){S.modal={m:'delG',v:''};layer();},doDelG(){S.modal=null;layer();toast(icon('check')+'Grupa usunięta (makieta).');}};
ON('input',e=>{const t=e.target;
 if(t.dataset.m&&S.modal){S.modal[t.dataset.m]=t.value;const s=app.querySelector('#isum');if(s)s.textContent=sumTxt(S.modal);const k=t.parentNode.nextElementSibling;if(k&&k.classList.contains('k'))k.textContent=pl(+t.value||0,'osoba','osoby','osób');}
 if(t.dataset.s){S.f[t.dataset.s]=t.value;const d=JSON.stringify(S.f)!==S.orig,b=app.querySelector('[data-act=saveSet]'),k=app.querySelector('.wbar .k');if(b)b.disabled=!d;if(k)k.textContent=d?'Niezapisane zmiany':'Brak zmian';}
 if(t.dataset.g!=null){S.modal.v=t.value;const b=app.querySelector('[data-act=doDelG]');if(b)b.disabled=t.value.trim()!==JSON.parse(S.orig).name;}});
DON('keydown',e=>{if(e.key==='Escape'&&S.modal)ACT.close();});

const ROUTES_OF = {inv: 't/invites', set: 't/group-settings', start: 's/start'};
delete ACT.theme;
ACT.go = a => nav(ROUTES_OF[a.dataset.v] || a.dataset.to);
ACT.openGroup = a => (a.dataset.g === 'kk' ? nav(a.dataset.to || 's/home') : CORE_ACT.stub(a));

reg('isg', {
  act: ACT, layer,
  closeLayer() { S.modal = null; },
  setView(v) { S.view = v; S.modal = null; S.err = {}; },
  page() {
    setRoute(ROUTES_OF[S.view]);
    if (S.view === 'set' && !S.f) { S.f = {...F0}; S.orig = JSON.stringify(S.f); }
    return `<div class="page">${{inv: vInv, set: vSet, start: vStart}[S.view]()}</div>`;
  }
});
})();
