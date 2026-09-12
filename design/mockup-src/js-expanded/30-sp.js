/* ===== module: sp (student pages + states gallery, from t/sp.html) ===== */
(() => {
const ON = (t, f) => on('sp', t, f), DON = (t, f) => ondoc('sp', t, f);
const ME = DB.me();
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
/*SHARED*/
Object.assign(IC,{history:'<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5M12 7v5l3 3"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const glyph=n=>`<svg class="gph" viewBox="0 0 64 64" aria-hidden="true">${GL[n]||''}</svg>`;
const mini=(c,g)=>`<span class="card ${c} mc"><span class="card-f"><span class="card-i">${glyph(g)}</span></span></span>`;
const bar=(v,m)=>`<div class="bar"><i style="--p:${Math.round(Math.min(v,m)/m*100)}%"></i></div>`;
const MARK='<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M12 1h16l11 11v16L28 39H12L1 28V12z" style="fill:var(--badge)"/><text x="20" y="25.4" text-anchor="middle" style="font:800 15px Bricolage Grotesque,sans-serif;fill:var(--card)">GH</text></svg>';
const RAB="url('__RABBITS__')";
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',view:'items',filter:'all',loading:false};
const head=(t,l,extra='')=>`<section class="panel phead"><div class="phead-t"><h1>${t}</h1><p class="lead">${l}</p></div>${extra}</section>`;
const itemCard=(it,foot,cls='')=>`<article class="card item full ${cls}"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name">${esc(it.name)}</h3></div><div class="art">${glyph(it.glyph)}</div><p class="rules">${esc(it.rules)}</p><p class="flavor">${esc(it.flavor)}</p><div class="card-foot">${foot}</div></div></div></article>`;
/* ---------- student pages ---------- */
function vItems(){return head('Moje przedmioty',`${ME.items.length} ${pl(ME.items.length,'przedmiot','przedmioty','przedmiotów')}. Wykorzystanie przedmiotu zgłaszasz prowadzącemu na zajęciach.`,`<button class="btn sec" data-act="go" data-to="s/shop">${icon('bag')}Przejdź do sklepu</button>`)+
 `<div class="pgrid">${ME.items.map(o=>itemCard(ITEM[o.id],`<span class="small">Kupione ${o.when}, za ${o.paid}</span>`)).join('')}<div class="panel slot-e" style="margin:0;width:auto"><p>Stać cię teraz na ${(()=>{const n=shopItems().filter(it=>itemState(it).state==='afford').length;return n+' '+pl(n,'przedmiot','przedmioty','przedmiotów');})()} w sklepie.</p><button class="btn sec" data-act="go" data-to="s/shop">Zobacz sklep</button></div></div>`;}
function vRanks(){const ri=rankIdx(ME.tot);return head('Rangi','Ranga rośnie razem z łącznie zebranymi marchewkami. Wydawanie ich jej nie obniża.')+
 `<ol class="panel sl">${RANKS.map((r,i)=>({r,i})).reverse().map(({r,i})=>{const nx=RANKS[i+1],st=i<ri?'done':i===ri?'cur':'lock';
 return `<li class="srk ${st==='cur'?'cur':st==='lock'?'lock':''}">${mini('gold',r.glyph)}<div><b>${esc(r.name)}${st==='cur'?' <span class="youtag">Twoja ranga</span>':''}</b><small>${i?`Od ${r.min} zebranych. Daje −${r.disc}% w sklepie.`:'Ranga startowa.'}</small></div>
 <div>${st==='done'?`<span class="st3 ok">${icon('check')}Zdobyta</span>`:st==='cur'&&nx?`<span class="st3">${ME.tot} z ${nx.min} do następnej</span>${bar(ME.tot-r.min,nx.min-r.min)}`:st==='cur'?'<span class="st3 ok">Najwyższa ranga</span>':`<span class="st3">${icon('lock')}Brakuje ${r.min-ME.tot}</span>`}</div></li>`;}).join('')}</ol>`;}
function vBadges(){const n=ME.badges.length;return head('Odznaki',`Masz ${n} z ${BADGES.length}. Odznaki przyznaje prowadzący. Na odwrocie każdej niezdobytej znajdziesz, jak ją zdobyć.`)+
 `<div class="cards cards-b" style="margin-top:22px">${BADGES.map(b=>{const e=ME.badges.includes(b.id);return `<article class="card badge flip${e?'':' down'}" aria-label="Odznaka ${esc(b.name)}${e?'':', niezdobyta'}"><div class="flip-in">
 <div class="face front"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name">${esc(b.name)}</h3></div><div class="art">${glyph(b.glyph)}</div><p class="rules">${esc(b.rule)}</p><p class="flavor">${esc(b.flavor)}</p><div class="card-foot"><span class="tag tag-disc">−${b.disc}% w sklepie</span></div></div></div></div>
 <div class="face back"><div class="card-f"><div class="card-i back-i"><div class="back-art">${MARK}</div><h3 class="card-name">${esc(b.name)}</h3><p class="how"><span>Jak zdobyć</span>${esc(b.rule)}</p></div></div></div></div></article>`;}).join('')}</div>`;}
function vHist(){let run=ME.bal;const rows=DB.me().hist.map(({amt:a,type:t,t:x,when:w,ctx:c})=>{const r={a,t,x,w,c,after:run};run-=a;return r;}),f=S.filter==='all'?rows:rows.filter(r=>r.t===S.filter),TL={earn:'Nagroda',spend:'Zakup',corr:'Korekta'};
 const fc=(k,l)=>`<button class="fchip" data-act="filter" data-v="${k}" aria-pressed="${S.filter===k}">${l}</button>`;
 return head('Historia waluty',`Masz <b>${ME.bal}</b> do wydania i <b>${ME.tot}</b> zebrane łącznie.`)+`<section class="panel tp" style="margin-top:22px;padding:20px 22px"><div class="filters" role="group" aria-label="Pokaż">${fc('all','Wszystkie')}${fc('earn','Nagrody')}${fc('spend','Zakupy')}${fc('corr','Korekty')}</div>
 <div role="table" aria-label="Historia waluty"><div class="lrow h" role="row"><span role="columnheader">Kwota</span><span role="columnheader">Typ</span><span role="columnheader">Za co</span><span role="columnheader">Kiedy</span><span role="columnheader" style="text-align:right">Saldo po</span></div>
 ${f.length?f.map(r=>`<div class="lrow" role="row"><span class="amt ${r.t}" role="cell">${r.a>0?'+':'−'}${Math.abs(r.a)}</span><span role="cell"><span class="ty ${r.t}">${TL[r.t]}</span></span><span class="src" role="cell">${esc(r.x)}${r.c?`<small>${esc(r.c)}</small>`:''}</span><span class="dt" role="cell">${r.w}</span><span class="bal2" role="cell">${r.after}</span></div>`).join(''):`<p class="expl" style="margin-top:12px">Nie masz jeszcze wpisów tego typu.</p>`}</div></section>`;}
/* ---------- states gallery ---------- */
function vStates(){const P=(cap,inner,cls='st-p')=>`<div><p class="cap" lang="en">${cap}</p><section class="panel ${cls}">${inner}</section></div>`;
 return head('Stany i komunikaty','Katalog stanów pustych i błędów. Każdy mówi, co się stało i co zrobić dalej.')+`<div class="gal">
 ${P('404: page not found',`<div class="bigno">404</div><h2 class="h2">Nie ma takiej strony</h2><p class="lead">Link mógł być niepełny albo strona została usunięta.</p><div class="rowb"><button class="btn" data-act="hint">Wróć na start</button></div>`)}
 ${P('No access to a group',`<div class="bigno lk">${icon('lock')}</div><h2 class="h2">Nie masz dostępu do tej grupy</h2><p class="lead">Nie należysz już do grupy albo prowadzący Cię usunął. Żeby wrócić, potrzebujesz kodu od prowadzącego.</p><div class="rowb"><button class="btn" data-act="hint">Dołącz z kodem</button><button class="btn sec" data-act="hint">Moje grupy</button></div>`)}
 ${P('Join: code errors (inline, under the code)',`<h2 class="h2" style="text-align:left">Dołącz do grupy</h2>${[['ABC123','Nie znaleźliśmy takiego kodu. Sprawdź go z prowadzącym.'],['T2KWR7','Ten kod wygasł. Poproś prowadzącego o nowy.'],['Z4QHR9','Z tego kodu skorzystała już maksymalna liczba osób. Poproś prowadzącego o nowy.'],['K7RB2Q','Już należysz do tej grupy. <button class="linkbtn">Otwórz grupę</button>',1]].map(([c,e,i])=>`<div class="jr"><code>${c}</code>${i?`<p class="hint" style="margin:0">${e}</p>`:`<p class="err">${icon('alert')}<span>${e}</span></p>`}</div>`).join('')}`)}
 ${P('Teacher: no groups yet',`<div class="bigno">${icon('cards')}</div><h2 class="h2">Utwórz pierwszą grupę</h2><p class="lead">Szybki start przygotuje rangi, odznaki, przedmioty i arkusz ocen. Zajmie to kilka minut.</p><div class="rowb"><button class="btn" data-act="hint">${icon('plus')}Utwórz grupę</button></div>`)}
 ${P('Student: not in any group',`<div class="bigno">${icon('plus')}</div><h2 class="h2">Dołącz do pierwszej grupy</h2><p class="lead">Wpisz 6-znakowy kod od prowadzącego albo zeskanuj kod QR aparatem telefonu.</p><div class="rowb"><button class="btn" data-act="hint">Dołącz do grupy</button></div>`)}
 ${P('Student: empty shop',`<div class="bigno lk">${icon('bag')}</div><h2 class="h2">Sklep jest jeszcze pusty</h2><p class="lead">Prowadzący nie dodał jeszcze przedmiotów. Zbieraj marchewki, przydadzą się później.</p>`)}
 ${P('Student: new, 0 currency',`<div class="bigno lk">${icon('podium')}</div><h2 class="h2">Pierwsze marchewki zdobędziesz na zajęciach</h2><p class="lead">Prowadzący przyznaje je za obecność, punktualność i aktywność. Zajrzyj tu po zajęciach.</p>`)}
 ${P('Item removed from the shop (soft delete): stays in history',itemCard(ITEM.kons,`<span class="small">Kupione 03.06, za 15</span>`,'gone').replace('<div class="card-top">','<div class="tags" style="padding:12px 12px 0"><span class="tag t-del">Usunięty z oferty</span></div><div class="card-top">'),'st-p" style="text-align:left;padding:18px')}
 </div>`;}
/* ---------- loading skeleton (same layout as My items) ---------- */
function vSkeleton(){const card=`<article class="card skc"><div class="card-f"><div class="card-i"><div class="sk skt"></div><div class="sk ska"></div><div class="sk skl"></div><div class="sk skl"></div><div class="sk skl" style="width:70%"></div><div class="sk skb" style="height:56px"></div></div></div></article>`;
 return `<section class="panel phead" aria-busy="true"><div class="phead-t"><div class="sk skh"></div><div class="sk skp"></div></div></section><div class="pgrid" aria-hidden="true">${card}<div class="panel slot-e" style="margin:0;width:auto"><div class="sk skl" style="margin:0"></div><div class="sk skb" style="margin:14px 0 0;width:60%"></div></div></div><p class="sr" role="status">Wczytywanie…</p>`;}
/* ---------- shell ---------- */
const VIEWS={items:vItems,ranks:vRanks,badges:vBadges,hist:vHist,states:vStates};
const ACT={theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},hint(){hint('Opens another screen (built separately).');},go(a){S.view=a.dataset.v;render();},filter(a){S.filter=a.dataset.v;render(true);}};

const ROUTES_OF = {items: 's/my-items', ranks: 's/ranks', badges: 's/badges', hist: 's/history', states: 's/states'};
delete ACT.hint;
ACT.go = a => nav(a.dataset.v && ROUTES_OF[a.dataset.v] ? ROUTES_OF[a.dataset.v] : a.dataset.to);

reg('sp', {
  act: ACT,
  setView(v) { if (v === 'loading') { S.view = 'items'; S.loading = true; setTimeout(() => { S.loading = false; if ((ROUTE[G.route] || {}).view === 'loading') { G.route = 's/my-items'; location.hash = '#/s/my-items'; } render(false); }, 1700); } else { S.view = v; S.loading = false; } },
  page() {
    if (!S.loading) setRoute(ROUTES_OF[S.view]);
    return `<div class="page">${S.loading ? vSkeleton() : VIEWS[S.view]()}</div>`;
  }
});
})();
