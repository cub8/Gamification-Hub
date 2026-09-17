/* ===== module: lists (teacher lists + join-code modal, from t/lists.html) ===== */
(() => {
const ON = (t, f) => on('lists', t, f), DON = (t, f) => ondoc('lists', t, f);
const STUD = DB.students;
const NOWD = new Date('2026-09-11T12:00');
const invActive = v => (!v.max || v.uses < v.max) && (!v.exp || new Date(v.exp) > NOWD);
const activeInv = () => DB.invites.filter(invActive);
const dmy = iso => iso ? iso.slice(8, 10) + '.' + iso.slice(5, 7) + ', ' + iso.slice(11, 16) : null;
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
/*SHARED*/
Object.assign(IC,{minus:'<path d="M5 12h14"/>',coins:'<path d="M4 7c0-1.7 3.6-3 8-3s8 1.3 8 3-3.6 3-8 3-8-1.3-8-3z"/><path d="M4 7v5c0 1.7 3.6 3 8 3s8-1.3 8-3V7M4 12v5c0 1.7 3.6 3 8 3s8-1.3 8-3v-5"/>',history:'<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5M12 7v5l3 3"/>',edit:'<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13 7l4 4"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const glyph=n=>`<svg class="gph" viewBox="0 0 64 64" aria-hidden="true">${GL[n]||''}</svg>`;
const mini=(cls,g)=>`<span class="card ${cls} mc"><span class="card-f"><span class="card-i">${glyph(g)}</span></span></span>`;
const bar=(v,m)=>`<div class="bar"><i style="--p:${m?Math.round(v/m*100):0}%"></i></div>`;
const hearts=(n,max)=>`<span class="hearts">${Array.from({length:Math.max(n,max)},(_,i)=>icon('heart',i<n?'hf':'he')).join('')}</span>`;
const initials=n=>n.split(/\s+/).map(w=>w[0]).join('').slice(0,2).toUpperCase(),hue=n=>[...n].reduce((a,c)=>a+c.charCodeAt(0),0)%5;
const RAB="url('__RABBITS__')";
const BOUGHT={popr:7,min5:5,kons:4,oneup:1,bezp:2,zal:1,p5:2};
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',view:'ranks',q:'',modal:false};
const holders=id=>STUD.filter(s=>s.b.includes(id)).length;
/* ---------- views ---------- */
function head(t,lead,btns){return `<section class="panel phead"><div class="phead-t"><h1>${t}</h1><p class="lead">${lead}</p></div><div class="acts">${btns}</div></section>`;}
function vRanks(){const by=RANKS.map((_,i)=>STUD.filter(s=>rankIdx(s.tot)===i).length),req=i=>ITEMS.filter(it=>it.req&&it.req.rank===i).map(it=>it.name);
 const rows=RANKS.map((r,i)=>({r,i})).reverse();
 return head('Rangi',`${RANKS.length} ${pl(RANKS.length,'ranga','rangi','rang')}. Ranga zależy od łącznie zebranych marchewek, więc wydawanie ich jej nie obniża.`,`<button class="btn" data-act="nav" data-to="t/rank-new">${icon('plus')}Nowa ranga</button>`)+
 `<section class="panel lst"><ol class="rlad">${rows.map(({r,i},k)=>`${k?`<li class="gap" aria-hidden="true">${r.min===0?'':''}↑ ${RANKS[i+1].min-r.min} zebranych do awansu</li>`:''}<li class="rl">${mini('gold',r.glyph)}<div><b>${esc(r.name)}</b><small>${i?`Od ${r.min} zebranych, −${r.disc}% w sklepie`:'Ranga startowa, bez zniżki'}</small>${req(i).length?`<small class="req2">Wymagana do zakupu: ${esc(req(i).join(', '))}</small>`:''}</div>
 <div class="rl-s"><b>${by[i]}</b>${pl(by[i],'student','studentów','studentów')}${bar(by[i],STUD.length)}</div><button class="btn sec sm" data-act="nav" data-to="t/rank-edit" data-i="${i}">${icon('edit')}Edytuj</button></li>`).join('')}</ol></section>`;}
function vBadges(){return head('Odznaki',`${BADGES.length} ${pl(BADGES.length,'odznaka','odznaki','odznak')}. Przyznajesz je ręcznie, z tej listy albo z listy studentów.`,`<button class="btn" data-act="nav" data-to="t/badge-new">${icon('plus')}Nowa odznaka</button>`)+
 `<div class="lgrid">${BADGES.map(b=>{const n=holders(b.id);return `<article class="card badge full"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name">${esc(b.name)}</h3></div><div class="art">${glyph(b.glyph)}</div>
 <div class="tags"><span class="tag tag-disc">−${b.disc}% w sklepie</span></div><p class="rules">${esc(b.rule)}</p><p class="flavor">${esc(b.flavor)}</p>
 <div class="card-foot"><span class="meta">${n?`Ma ją ${n} ${pl(n,'student','studentów','studentów')}`:'Nikt jej jeszcze nie ma'}</span><span style="display:flex;gap:6px"><button class="btn sm" data-act="nav" data-to="t/students">Przyznaj</button><button class="iconbtn" data-act="nav" data-to="t/badge-edit" data-i="${b.id}" aria-label="Edytuj ${esc(b.name)}">${icon('edit')}</button></span></div></div></div></article>`;}).join('')}</div>`;}
function vItems(){const IT=shopItems(),it=IT.slice().sort((a,b)=>a.cost-b.cost);
 return head('Przedmioty',`${IT.length} ${pl(IT.length,'przedmiot','przedmioty','przedmiotów')} w sklepie, od najtańszego.`,`<button class="btn" data-act="nav" data-to="t/item-new">${icon('plus')}Nowy przedmiot</button>`)+
 `<div class="lgrid">${it.map(x=>{const n=BOUGHT[x.id]||0,t=[];if(x.req&&x.req.rank!=null)t.push(`<span class="tag t-lock">${icon('lock')}Od rangi ${esc(RANKS[x.req.rank].name)}</span>`);((x.req&&x.req.badges)||[]).forEach(b=>t.push(`<span class="tag t-lock">${icon('lock')}${esc(BADGE[b].name)}</span>`));
 if(x.discBadges)t.push(`<span class="tag tag-disc">Zniżka za odznaki</span>`);if(x.zeroLives)t.push(`<span class="tag tag-life">${icon('heart')}Przy 0 życiach</span>`);
 return `<article class="card item full"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name">${esc(x.name)}</h3><span class="cost"><b>${x.cost}</b></span></div><div class="art">${glyph(x.glyph)}</div>${t.length?`<div class="tags">${t.join('')}</div>`:''}
 <p class="rules">${esc(x.rules)}</p><p class="flavor">${esc(x.flavor)}</p><div class="card-foot"><span class="meta">${n?`Kupiono ${n} ${pl(n,'raz','razy','razy')}`:'Jeszcze nikt nie kupił'}</span><button class="iconbtn" data-act="nav" data-to="t/item-edit" data-i="${x.id}" aria-label="Edytuj ${esc(x.name)}">${icon('edit')}</button></div></div></div></article>`;}).join('')}</div>`;}
function sRow(s,i){const r=RANKS[rankIdx(s.tot)];return `<li class="srow${s.lives===0?' zero':''}" data-i="${i}" data-act="student"><span class="s-n"><span class="av sm" data-h="${hue(s.name)}" aria-hidden="true">${initials(s.name)}</span><a href="#" class="s-link" data-act="student" data-i="${i}" style="min-width:0"><b>${esc(s.name)}</b><small>${s.email}</small></a></span>
 <span><span class="lbl-m">Ranga</span><span class="s-r">${esc(r.name)}</span></span>
 <span><span class="lbl-m">Życia</span><span class="lives"><button data-act="life" data-i="${i}" data-d="-1" aria-label="Odbierz życie: ${esc(s.name)}"${s.lives?'':' disabled'}>${icon('minus')}</button><span class="lv${s.lives?'':' z'}">${icon('heart')}<b>${s.lives}</b></span><button data-act="life" data-i="${i}" data-d="1" aria-label="Dodaj życie: ${esc(s.name)}">${icon('plus')}</button></span></span>
 <span><span class="lbl-m">Do wydania</span><span class="num2">${s.bal}</span></span><span><span class="lbl-m">Zebrane</span><span class="num2">${s.tot}</span></span><span><span class="lbl-m">Odznaki</span><span class="num2">${s.b.length}</span></span>
 <span class="s-a"><button class="iconbtn" data-act="student" data-i="${i}" data-tab="assign" aria-label="Przyznaj odznakę: ${esc(s.name)}" title="Przyznaj odznakę">${icon('badge')}</button><button class="iconbtn" data-act="student" data-i="${i}" data-tab="adjust" aria-label="Koryguj walutę: ${esc(s.name)}" title="Koryguj walutę">${icon('coins')}</button><button class="iconbtn" data-act="student" data-i="${i}" data-tab="hist" aria-label="Historia: ${esc(s.name)}" title="Historia transakcji">${icon('history')}</button></span></li>`;}
function vStudents(){const q=S.q.trim().toLowerCase(),list=STUD.map((s,i)=>[s,i]).filter(([s])=>!q||s.name.toLowerCase().includes(q)),zero=STUD.filter(s=>!s.lives).length;
 return head('Studenci',`Życie odbierasz za nieusprawiedliwioną nieobecność. ${zero?`<b>${zero} ${pl(zero,'student ma','studentów ma','studentów ma')} 0 żyć</b> i kupi tylko przedmioty dostępne przy 0 życiach.`:''}`,`<button class="btn sec" data-act="code">${icon('qr')}Pokaż kod dla studentów</button><button class="btn" data-act="nav" data-to="t/invites">${icon('plus')}Zaproś studenta</button>`)+
 `<div class="stbar"><label class="search">${icon('search')}<input type="search" data-q placeholder="Szukaj studenta" value="${esc(S.q)}" aria-label="Szukaj studenta"></label><span class="meta" id="cnt">${list.length} z ${STUD.length}</span></div>
 <section class="panel st"><ul style="list-style:none;margin:0;padding:0" role="list"><li class="srow h" aria-hidden="true"><span>Student</span><span>Ranga</span><span>Życia</span><span>Do wydania</span><span>Zebrane</span><span>Odznaki</span><span style="text-align:right">Akcje</span></li>${list.map(([s,i])=>sRow(s,i)).join('')}</ul></section>`;}
const VIEWS={ranks:vRanks,badges:vBadges,items:vItems,students:vStudents};
/* ---------- code modal (projectable) ---------- */
function qr(seed){let h=27,d='';const rnd=()=>(seed=(seed*9301+49297)%233280)/233280,fnd=(x,y)=>{d+=`M${x} ${y}h7v7h-7zM${x+1} ${y+1}v5h5v-5zM${x+2} ${y+2}h3v3h-3z`;};
 for(let y=0;y<h;y++)for(let x=0;x<h;x++){const inF=(x<8&&y<8)||(x>h-9&&y<8)||(x<8&&y>h-9);if(!inF&&rnd()>.52)d+=`M${x} ${y}h1v1h-1z`;}
 fnd(0,0);fnd(h-7,0);fnd(0,h-7);return `<svg class="qr" viewBox="0 0 ${h} ${h}" role="img" aria-label="Kod QR (podgląd w makiecie)"><path d="${d}" fill="#111" fill-rule="evenodd"/></svg>`;}
const short=x=>(x.max?`użyto ${x.uses}/${x.max}`:'bez limitu')+', '+(x.exp?`do ${dmy(x.exp).split(',')[0]}`:'bezterminowo');
const invTxt=v=>(v.max?`użyto ${v.uses} z ${v.max}`:`użyto ${v.uses} razy, bez limitu`)+', '+(v.exp?`wygasa ${dmy(v.exp)}`:'bez daty ważności');
function layer(){const L=app.querySelector('#layer');if(!S.modal){L.innerHTML='';L.classList.remove('on');return;}L.classList.add('on');
 const INV=activeInv();const v=INV[S.inv||0]||INV[0],seed=[...v.code].reduce((a,c)=>a+c.charCodeAt(0),0),t=invTxt(v);
 L.innerHTML=`<div class="ovl" data-act="close"><div class="dlg dlg-code" role="dialog" aria-modal="true" aria-labelledby="ct" data-act="noop"><div class="dlg-in"><span class="grab"></span><h2 class="h2" id="ct">Dołącz do grupy Kosmiczne króliki</h2><p>Wpisz kod w aplikacji („Dołącz do grupy”) albo zeskanuj kod QR.</p>
 ${INV.length>1?`<div class="fld"><label for="inv-s">Zaproszenie <small>(aktywne: ${INV.length}, najnowsze na górze)</small></label><span class="sel" style="display:flex"><select id="inv-s" data-inv style="flex:1">${INV.map((x,i)=>`<option value="${i}"${i===(S.inv||0)?' selected':''}>${x.code} – ${short(x)}</option>`).join('')}</select>${icon('chevDown')}</span><span class="hint">Wygasłe i wyczerpane zaproszenia są ukryte. Wszystkie znajdziesz w zakładce Zaproszenia.</span></div>`:''}
 <div class="qrbox">${qr(seed)}<div><div class="code-big" aria-label="Kod: ${v.code.split('').join(' ')}">${v.code}</div><p class="small" style="margin-top:12px">${t[0].toUpperCase()+t.slice(1)}.</p></div></div>
 <div class="dlg-b"><button class="btn sec" data-act="nav" data-to="t/invites">${icon('plus')}Zarządzaj zaproszeniami</button><button class="btn" data-act="close" data-focus>Zamknij</button></div></div></div></div>`;L.querySelector('[data-focus]').focus();}
/* ---------- shell ---------- */
const ACT={noop(){},theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},hint(){hint('Opens the matching form or modal (built separately).');},go(a){S.view=a.dataset.v;S.q='';render();},
 code(){S.modal=true;S.inv=0;layer();},inv(a){S.inv=+a.dataset.i;layer();},student(a){hint('Opens the detail page of '+STUD[+a.dataset.i].name+' (not built yet).');},close(){S.modal=false;layer();},copy(){toast(icon('check')+'Skopiowano kod K7RB2Q.');},
 life(a){const s=STUD[+a.dataset.i],d=+a.dataset.d;s.lives=Math.max(0,s.lives+d);render(true);
  toast(icon('heart')+(d<0?`Odebrano życie za nieusprawiedliwioną nieobecność: ${esc(s.name)} (zostało ${s.lives}).`:`Dodano życie: ${esc(s.name)} (ma ${s.lives}).`));}};
ON('input',e=>{if(e.target.dataset.q==null)return;S.q=e.target.value;const q=S.q.trim().toLowerCase();let n=0;app.querySelectorAll('.srow[data-i]').forEach(r=>{const h=!!q&&!STUD[+r.dataset.i].name.toLowerCase().includes(q);r.hidden=h;if(!h)n++;});app.querySelector('#cnt').textContent=`${n} z ${STUD.length}`;});
DON('keydown',e=>{if(e.key==='Escape'&&S.modal)ACT.close();});
ON('change',e=>{if(e.target.dataset.inv==null)return;S.inv=+e.target.value;layer();app.querySelector('#inv-s').focus();});

const ROUTES_OF = {ranks: 't/ranks', badges: 't/badges', items: 't/items', students: 't/students'};
ACT.go = a => nav(ROUTES_OF[a.dataset.v] || a.dataset.to);
ACT.student = a => nav('t/student', {i: +a.dataset.i, tab: a.dataset.tab});
delete ACT.theme;

reg('lists', {
  act: ACT, layer,
  closeLayer() { S.modal = false; },
  setView(v) { S.view = v; S.q = ''; S.modal = false; },
  page() { setRoute(ROUTES_OF[S.view]); return `<div class="page">${VIEWS[S.view]()}</div>`; }
});
})();
