/* ===== module: item (item create/edit form, from t/item.html) ===== */
(() => {
const ON = (t, f) => on('item', t, f), DON = (t, f) => ondoc('item', t, f);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
const andList=a=>a.length<2?a.join(''):a.slice(0,-1).join(', ')+' i '+a[a.length-1];
/*SHARED*/
Object.assign(IC,{minus:'<path d="M5 12h14"/>',upload:'<path d="M12 16V4M7 9l5-5 5 5M4 16v4h16v-4"/>',x:'<path d="M6 6l12 12M18 6L6 18"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',archive:'<path d="M3 4h18v5H3zM5 9v11h14V9M10 13h4"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const glyph=n=>`<svg class="gph" viewBox="0 0 64 64" aria-hidden="true">${GL[n]||''}</svg>`;
const bar=(v,m)=>`<div class="bar"><i style="--p:${Math.round(v/m*100)}%"></i></div>`;
const RAB="url('__RABBITS__')";
const PRE=['shield','hourglass','chat','retake','percent','paperCheck','heartPlus','note','clock','papers3','starPlus','flask'];
const BLANK={name:'',rules:'',story:'',art:'shield',upload:null,focal:[50,50],price:15,zero:false,unlockRank:-1,unlockBadges:[],discRank:-1,discBadges:[]};
const EDIT={...BLANK,name:'Bezpieczna poprawa',rules:'Możliwość ponownego napisania (poprawy) wejściówki z zamrożeniem obecnego wyniku',story:'Statek trafia do hangaru ochronnego',price:20,discBadges:['zawsze','agent']};
const clone=o=>JSON.parse(JSON.stringify(o));
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',mode:'create',pv:'afford',f:clone(BLANK),orig:JSON.stringify(BLANK),err:{},dlg:false};
const dirty=()=>JSON.stringify(S.f)!==S.orig;
const reqs=()=>{const f=S.f,r=[];if(f.unlockRank>0)r.push({t:'rank',r:RANKS[f.unlockRank]});f.unlockBadges.forEach(b=>r.push({t:'badge',b:BADGE[b]}));return r;};
function example(){const f=S.f,rk=Math.max(f.unlockRank,f.discRank,0),rp=f.discRank>0&&rk>=f.discRank?RANKS[rk].disc:0,bp=f.discBadges.reduce((a,b)=>a+BADGE[b].disc,0),pct=rp+bp;return{rk,pct,price:Math.max(0,Math.round(f.price*(1-pct/100)))};}
const artHtml=()=>S.f.art==='upload'?`<img src="${S.f.upload}" alt="" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:${S.f.focal[0]}% ${S.f.focal[1]}%">`:glyph(S.f.art);
const err=k=>S.err[k]?`<p class="err" id="e-${k}">${icon('alert')}${S.err[k]}</p>`:'';
const inp=(k,v,ph,a='')=>`<div class="inp${S.err[k]?' bad':''}"><input id="f-${k}" data-f="${k}" value="${esc(v)}" placeholder="${ph}"${S.err[k]?` aria-invalid="true" aria-describedby="e-${k}"`:''} ${a}></div>`;
const sel=(k,v,o,lab)=>`<span class="sel"><select data-sel="${k}" aria-label="${lab}">${o.map(([x,l])=>`<option value="${x}"${x===v?' selected':''}>${esc(l)}</option>`).join('')}</select>${icon('chevDown')}</span>`;
function chips(k,lab){const on=S.f[k],rest=BADGES.filter(b=>!on.includes(b.id)),d=k==='discBadges';
 return `<span class="chips">${on.map(id=>`<span class="chip">${esc(BADGE[id].name)}${d?`<small>−${BADGE[id].disc}%</small>`:''}<button data-act="unchip" data-k="${k}" data-v="${id}" aria-label="Usuń odznakę ${esc(BADGE[id].name)}">${icon('x')}</button></span>`).join('')}${rest.length?sel(k,'',[['',on.length?'Dodaj kolejną…':'Dodaj odznakę…'],...rest.map(b=>[b.id,b.name+(d?` (−${b.disc}%)`:'')])],lab):''}</span>`;}
function unlockText(){const f=S.f,r=f.unlockRank>0?RANKS[f.unlockRank].name:null,b=f.unlockBadges.map(id=>BADGE[id].name);
 const t=!r&&!b.length?'Każdy student może kupić ten przedmiot':'Kupią tylko studenci'+(r?` z rangą <b>${esc(r)}</b> lub wyższą`:'')+(b.length?`, którzy mają ${b.length>1?'wszystkie odznaki':'odznakę'} <b>${esc(andList(b))}</b>`:'');
 return t+(f.zero?'. Także przy 0 życiach.':', jeśli mają co najmniej 1 życie.');}
function exampleText(){const f=S.f,x=example(),bn=f.discBadges.map(id=>BADGE[id].name);
 if(!x.pct)return `Bez zniżek. Każdy kupujący zapłaci <b>${f.price}</b>.`;
 return `Przykład: student z rangą <b>${esc(RANKS[x.rk].name)}</b>${bn.length?` i ${bn.length>1?'odznakami':'odznaką'} <b>${esc(andList(bn))}</b>`:''} zapłaci <b>${x.price}</b> zamiast ${f.price} (−${x.pct}%).`;}
function warnings(){const f=S.f,w=[];
 if(f.discRank>0&&f.unlockRank>=f.discRank)w.push(`Kupić mogą tylko studenci od rangi ${RANKS[f.unlockRank].name}, więc zniżka dla rang obejmie każdego kupującego.`);
 f.discBadges.filter(b=>f.unlockBadges.includes(b)).forEach(b=>w.push(`Odznaka ${BADGE[b].name} jest wymagana do zakupu, więc jej zniżka obejmie każdego kupującego.`));
 return w.map(t=>`<p class="warn2">${icon('alert')}<span>${esc(t)}</span></p>`).join('');}
function form(){const f=S.f,ranks=RANKS.slice(1).map((r,i)=>[i+1,r]);
 return `${S.mode==='edit'?`<p class="info">${icon('users')}<span><b>2 studentów ma ten przedmiot.</b> Zmiany ceny, wymagań i zniżek dotyczą tylko nowych zakupów.</span></p>`:''}
 <div class="fsec"><h2 class="h3">Karta przedmiotu</h2><p class="hint">Tak przedmiot wygląda w sklepie i w ekwipunku studenta.</p>
  <div class="fld"><label for="f-name">Nazwa</label>${inp('name',f.name,'np. Poprawa wejściówki','maxlength="50" autocomplete="off"')}${err('name')}</div>
  <div class="fld"><label for="f-rules">Co daje studentowi</label><div class="inp${S.err.rules?' bad':''}"><textarea id="f-rules" data-f="rules" rows="2" style="font:400 15px/1.5 var(--f-text);min-height:72px" placeholder="np. Możliwość ponownego napisania wejściówki"${S.err.rules?' aria-invalid="true" aria-describedby="e-rules"':''}>${esc(f.rules)}</textarea></div>${err('rules')}<span class="hint">Opis dydaktyczny: konkretna korzyść, bez fabuły.</span></div>
  <div class="fld"><label for="f-story">Opis fabularny <small>(opcjonalnie)</small></label><div class="inp"><textarea id="f-story" data-f="story" rows="2" style="min-height:72px" placeholder="np. Awaryjny powrót statku do bazy">${esc(f.story)}</textarea></div></div>
  <div class="fld"><p class="lbl">Grafika</p><div class="pz-grid" role="radiogroup" aria-label="Gotowe grafiki">${PRE.map(k=>`<button class="pz glp" role="radio" aria-checked="${f.art===k}" data-act="art" data-v="${k}" aria-label="Grafika ${k}"><i>${glyph(k)}</i></button>`).join('')}${f.upload?`<button class="pz" role="radio" aria-checked="${f.art==='upload'}" data-act="art" data-v="upload" aria-label="Twoja grafika"><i style="background-image:url('${f.upload}')"></i></button>`:''}</div>
  <div class="drop"><span class="drop-ic">${icon('upload')}</span><span><b>Albo wgraj własną grafikę</b><small>JPG lub PNG, najlepiej co najmniej 400 px.</small></span><label class="btn sec sm">Wybierz plik<input type="file" accept="image/*" data-file="art" class="sr"></label></div>
  ${f.art==='upload'?`<div class="fld"><p class="lbl">Najważniejszy fragment</p><div class="focal"><img src="${f.upload}" alt="Podgląd grafiki" data-act="focal"><span class="mk" style="left:${f.focal[0]}%;top:${f.focal[1]}%"></span></div><span class="hint">Kliknij obraz, żeby wskazać, co ma zostać widoczne po przycięciu.</span></div>`:''}</div></div>
 <div class="fsec"><h2 class="h3">Cena</h2>
  <div class="price-row"><div class="inp num${S.err.price?' bad':''}"><input id="f-price" type="number" min="1" data-f="price" value="${f.price}" aria-label="Cena"></div><span class="tok" style="--s:32px"><span><svg viewBox="0 0 24 24">${CI.carrot}</svg></span></span><span class="k" id="pn">${pl(f.price,CUR.carrot.nom1,CUR.carrot.nom2,CUR.carrot.gen5)}</span></div>${err('price')}
  <div class="swrow"><button class="sw" role="switch" aria-checked="${f.zero}" data-act="zero" aria-labelledby="l-zero"><i></i></button><span><b id="l-zero">Można kupić przy 0 życiach</b><span class="hint">Przydaje się dla przedmiotów, które przywracają życie.</span></span></div></div>
 <div class="fsec"><h2 class="h3">Kto może kupić</h2><p class="hint">Bez wymagań przedmiot jest dostępny dla wszystkich.</p>
  <div class="sent"><span>Kupić może</span>${sel('unlockRank',f.unlockRank,[[-1,'każdy student'],...ranks.map(([i,r])=>[i,'od rangi '+r.name])],'Kto może kupić')}</div>
  <div class="sent"><span>Wymagane odznaki</span>${chips('unlockBadges','Dodaj wymaganą odznakę')}</div>
  <p class="expl" id="ex-u">${unlockText()}</p></div>
 <div class="fsec"><h2 class="h3">Zniżki</h2><p class="hint">Zniżka z rangi to procent przypisany do rangi studenta. Zniżki z odznak się sumują.</p>
  <div class="sent"><span>Zniżka dla rang</span>${sel('discRank',f.discRank,[[-1,'brak'],...ranks.map(([i,r])=>[i,`od ${r.name} (−${r.disc}% i więcej)`])],'Zniżka dla rang')}</div>
  <div class="sent"><span>Zniżka za odznaki</span>${chips('discBadges','Dodaj odznakę ze zniżką')}</div>
  <p class="expl" id="ex-d">${exampleText()}</p><div id="warns">${warnings()}</div></div>
 ${S.mode==='edit'?`<div class="fsec"><h2 class="h3">Usuwanie</h2><p class="hint">Przedmiot zniknie ze sklepu i z list. Studenci, którzy go kupili, nadal go mają, a w ich historii zostanie jako „Usunięty z oferty”.</p><div class="rowb" style="margin-top:12px"><button class="btn sec" data-act="archive">${icon('trash')}Usuń przedmiot</button></div></div>`:''}`;}
function pvCard(){const f=S.f,rq=reqs(),st=S.pv==='sealed'&&!rq.length?'afford':S.pv,x=example(),need=Math.max(1,Math.min(6,f.price-1));
 const tags=[];if(x.pct)tags.push(`<span class="tag tag-disc">Zniżki do −${x.pct}%</span>`);if(f.zero)tags.push(`<span class="tag tag-life">${icon('heart')}Działa przy 0 życiach</span>`);
 const foot=st==='afford'?`<button class="btn" tabindex="-1">Kup za ${f.price}</button>`:st==='save'?`<div class="need"><div class="need-t">Zbierz jeszcze <b>${need}</b></div>${bar(f.price-need,f.price)}</div>`
  :`<div class="req">${rq.map(r=>r.t==='rank'?`Wymaga rangi <b>${esc(r.r.name)}</b>.`:`Wymaga odznaki <b>${esc(r.b.name)}</b>.`).join('<br>')}</div>`;
 return `<article class="card item ${st} full"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name${f.name?'':' ph'}">${esc(f.name||'Nazwa przedmiotu')}</h3><span class="cost"><b>${f.price}</b></span></div>
 <div class="art">${artHtml()}${st==='sealed'?`<span class="seal">${icon('lock')}<span>${esc(rq[0].t==='rank'?'Od rangi '+rq[0].r.name:'Za odznakę '+rq[0].b.name)}</span></span>`:''}</div>
 ${tags.length?`<div class="tags">${tags.join('')}</div>`:''}<p class="rules${f.rules?'':' ph'}">${esc(f.rules||'Co daje studentowi…')}</p>${f.story?`<p class="flavor">${esc(f.story)}</p>`:''}<div class="card-foot">${foot}</div></div></div></article>`;}
function preview(){const rq=reqs();return `<details class="pvd" open><summary>Podgląd karty ${icon('chevDown')}</summary><section class="panel pv"><h3>Tak zobaczą to studenci</h3>
 <div class="seg2" role="group" aria-label="Stan karty">${[['afford','Dostępny'],['save','Zbierasz'],['sealed','Zapieczętowany']].map(([k,l])=>`<button data-act="pv" data-v="${k}" aria-pressed="${S.pv===k&&!(k==='sealed'&&!rq.length)}"${k==='sealed'&&!rq.length?' disabled':''}>${l}</button>`).join('')}</div>
 ${rq.length?'':'<span class="hint">Bez wymagań przedmiot nigdy nie będzie zapieczętowany.</span>'}<div class="pvcard">${pvCard()}</div></section>
 <section class="panel pv"><h3>Miniatura w powiadomieniach</h3><div class="thumbrow"><span class="card item mc"><span class="card-f"><span class="card-i">${artHtml()}</span></span></span><span><b>${esc(S.f.name||'Nazwa przedmiotu')}</b><span class="small">Sebastian Alejandro, dziś 10:21</span></span></div></section></details>`;}
function wbar(){const d=dirty();return `<div class="panel wbar"><button class="linkbtn" data-act="cancel">Anuluj</button><span class="sp"></span>${S.mode==='edit'?`<span class="k" id="dk">${d?'Niezapisane zmiany':'Brak zmian'}</span><button class="btn" data-act="save" id="sv"${d?'':' disabled'}>Zapisz zmiany</button>`:`<button class="btn" data-act="save">${icon('plus')}Dodaj przedmiot</button>`}</div>`;}
function refresh(){const p=app.querySelector('.pcol');if(p){const o=p.querySelector('.pvd').open;p.innerHTML=preview();p.querySelector('.pvd').open=o;}
 const set=(id,h)=>{const e=app.querySelector('#'+id);if(e)e.innerHTML=h;};set('ex-u',unlockText());set('ex-d',exampleText());set('warns',warnings());set('pn',pl(S.f.price,CUR.carrot.nom1,CUR.carrot.nom2,CUR.carrot.gen5));
 const d=dirty(),k=app.querySelector('#dk'),b=app.querySelector('#sv');if(k)k.textContent=d?'Niezapisane zmiany':'Brak zmian';if(b)b.disabled=!d;}
function layer(){const L=app.querySelector('#layer');if(!S.dlg){L.innerHTML='';L.classList.remove('on');return;}L.classList.add('on');
 L.innerHTML=`<div class="ovl" data-act="close"><div class="dlg" role="dialog" aria-modal="true" aria-labelledby="dt" data-act="noop"><div class="dlg-in"><span class="grab"></span>${S.dlg==='del'?`<h2 class="h2" id="dt">Usunąć „${esc(S.f.name)}” ze sklepu?</h2><p>Przedmiot zniknie ze sklepu i z list. Studenci, którzy go kupili, zachowają go, a w historii zostanie oznaczony jako „Usunięty z oferty”.</p><div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Anuluj</button><button class="btn" data-act="doDelete">Usuń z oferty</button></div>`:`<h2 class="h2" id="dt">Odrzucić zmiany?</h2><p>Niezapisane zmiany w tym przedmiocie zostaną utracone.</p><div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Wróć do edycji</button><button class="btn" data-act="discard">Odrzuć zmiany</button></div>`}</div></div></div>`;L.querySelector('[data-focus]').focus();}
function validate(){const f=S.f;S.err={};if(!f.name.trim())S.err.name='Podaj nazwę przedmiotu.';if(!f.rules.trim())S.err.rules='Napisz, co przedmiot daje studentowi.';if(!(f.price>=1))S.err.price='Cena musi wynosić co najmniej 1.';return !Object.keys(S.err).length;}
const ACT={noop(){},close(){S.dlg=false;layer();},theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},
 art(a){S.f.art=a.dataset.v;render(true);},zero(){S.f.zero=!S.f.zero;render(true);},pv(a){S.pv=a.dataset.v;refresh();},
 unchip(a){const k=a.dataset.k;S.f[k]=S.f[k].filter(x=>x!==a.dataset.v);render(true);},
 focal(a,e){const r=a.getBoundingClientRect();S.f.focal=[Math.round((e.clientX-r.left)/r.width*100),Math.round((e.clientY-r.top)/r.height*100)];const k=app.querySelector('.mk');k.style.left=S.f.focal[0]+'%';k.style.top=S.f.focal[1]+'%';refresh();},
 save(){if(!validate()){render(true);const f=app.querySelector('[aria-invalid="true"]');if(f)f.focus();return;}
  if(S.mode==='edit'){S.orig=JSON.stringify(S.f);render(true);toast(icon('check')+'Zapisano zmiany. Dotyczą nowych zakupów.');}else toast(icon('check')+`Dodano przedmiot „${esc(S.f.name)}” do sklepu.`);},
 cancel(){if(dirty()){S.dlg=true;layer();}else hint('Would return to the items list.');},discard(){S.f=JSON.parse(S.orig);S.dlg=false;S.err={};render(true);},
 archive(){toast(icon('archive')+'Przedmiot zarchiwizowany. Studenci nadal go mają.');}};
ON('input',e=>{const t=e.target,k=t.dataset.f;if(!k)return;S.f[k]=k==='price'?Math.max(0,parseInt(t.value,10)||0):t.value;
 if(S.err[k]&&(k==='price'?S.f.price>=1:String(S.f[k]).trim())){delete S.err[k];t.parentNode.classList.remove('bad');t.removeAttribute('aria-invalid');const m=app.querySelector('#e-'+k);if(m)m.remove();}refresh();});
ON('change',e=>{const t=e.target;if(t.dataset.sel){const k=t.dataset.sel;if(k.endsWith('Badges')){if(t.value)S.f[k].push(t.value);}else S.f[k]=+t.value;render(true);return;}
 if(t.dataset.file&&t.files[0]){const r=new FileReader();r.onload=()=>{S.f.upload=r.result;S.f.art='upload';S.f.focal=[50,50];render(true);};r.readAsDataURL(t.files[0]);}});
DON('keydown',e=>{if(e.key==='Escape'&&S.dlg)ACT.close();});
function setMode(m){S.mode=m;S.f=clone(m==='edit'?EDIT:BLANK);S.orig=JSON.stringify(S.f);S.err={};S.pv='afford';S.dlg=false;render();}

const fromItem = it => ({...clone(BLANK), id: it.id, name: it.name, rules: it.rules, story: it.flavor, art: it.glyph,
  price: it.cost, zero: !!it.zeroLives,
  unlockRank: it.req && it.req.rank != null ? it.req.rank : -1,
  unlockBadges: ((it.req && it.req.badges) || []).slice(),
  discRank: -1, discBadges: (it.discBadges || []).slice()});
const toItem = f => ({id: f.id || ('x' + Date.now().toString(36)), name: f.name.trim(), cost: +f.price, glyph: f.art,
  flavor: f.story.trim(), rules: f.rules.trim(),
  zeroLives: f.zero || undefined,
  discBadges: f.discBadges.length ? f.discBadges.slice() : undefined,
  req: (f.unlockRank > 0 || f.unlockBadges.length)
    ? {...(f.unlockRank > 0 ? {rank: f.unlockRank} : {}), ...(f.unlockBadges.length ? {badges: f.unlockBadges.slice()} : {})}
    : undefined});

['theme'].forEach(k => delete ACT[k]);
ACT.cancel = function () { if (dirty()) { S.dlg = true; layer(); } else nav('t/items'); };
ACT.discard = function () { S.f = JSON.parse(S.orig); S.dlg = false; S.err = {}; nav('t/items'); };
ACT.save = function () {
  if (!validate()) { render(true); const f = app.querySelector('[aria-invalid="true"]'); if (f) f.focus(); return; }
  const data = toItem(S.f);
  if (S.mode === 'edit') {
    const it = ITEM[S.f.id]; Object.assign(it, data); ITEM[it.id] = it;
    nav('t/items'); toast(icon('check') + `Zapisano „${esc(it.name)}”. Zmiany dotyczą nowych zakupów.`);
  } else {
    ITEMS.push(data); ITEM[data.id] = data;
    nav('t/items'); toast(icon('check') + `Dodano przedmiot „${esc(data.name)}” do sklepu.`);
  }
};
ACT.archive = function () { S.dlg = 'del'; layer(); };
ACT.doDelete = function () {
  const it = ITEM[S.f.id]; DB.soldOut[it.id] = true; S.dlg = false;
  nav('t/items'); toast(icon('check') + `Usunięto „${esc(it.name)}” z oferty. Kupione egzemplarze zostają u studentów.`);
};

reg('item', {
  act: ACT, layer,
  closeLayer() { S.dlg = false; },
  setView(v, o) {
    S.mode = v === 'edit' ? 'edit' : 'create';
    const src = (o && o.i && ITEM[o.i]) || ITEM.bezp;
    S.f = S.mode === 'edit' ? fromItem(src) : clone(BLANK);
    S.orig = JSON.stringify(S.f); S.err = {}; S.pv = 'afford'; S.dlg = false;
  },
  page() {
    setRoute(S.mode === 'edit' ? 't/item-edit' : 't/item-new');
    return `<div class="page">
      <section class="panel phead" style="display:block"><p class="crumbs"><a href="#/t/items" data-act="nav" data-to="t/items">Przedmioty</a>${icon('chevRight')}<span>${S.mode === 'edit' ? esc(JSON.parse(S.orig).name) : 'Nowy przedmiot'}</span></p><h1>${S.mode === 'edit' ? 'Edytuj przedmiot' : 'Nowy przedmiot'}</h1><p class="lead">${S.mode === 'edit' ? 'Podgląd obok pokazuje kartę po zmianach.' : 'Wypełnij kartę, a podgląd obok pokaże, jak zobaczą ją studenci.'}</p></section>
      <div class="wiz"><section class="panel fcol">${form()}</section><aside class="pcol" aria-label="Podgląd">${preview()}</aside></div>
      <div style="margin-bottom:14px">${wbar()}</div></div>`;
  }
});
})();
