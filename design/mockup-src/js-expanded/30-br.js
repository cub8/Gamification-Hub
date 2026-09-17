/* ===== module: br (badge + rank forms, from t/br.html) ===== */
(() => {
const ON = (t, f) => on('br', t, f), DON = (t, f) => ondoc('br', t, f);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
const andList=a=>a.length<2?a.join(''):a.slice(0,-1).join(', ')+' i '+a[a.length-1];
/*SHARED*/
Object.assign(IC,{minus:'<path d="M5 12h14"/>',upload:'<path d="M12 16V4M7 9l5-5 5 5M4 16v4h16v-4"/>',x:'<path d="M6 6l12 12M18 6L6 18"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',archive:'<path d="M3 4h18v5H3zM5 9v11h14V9M10 13h4"/>',trash:'<path d="M4 6h16M9 6V3h6v3M6 6l1 15h10l1-15"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const glyph=n=>`<svg class="gph" viewBox="0 0 64 64" aria-hidden="true">${GL[n]||''}</svg>`;
const MARK='<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M12 1h16l11 11v16L28 39H12L1 28V12z" style="fill:var(--badge)"/><text x="20" y="25.4" text-anchor="middle" style="font:800 15px Bricolage Grotesque,sans-serif;fill:var(--card)">GH</text></svg>';
const RAB="url('__RABBITS__')";
const PRE={badge:['rabbit','rocket','carrot','compass','starTrail','wrench','bolt','crew','crown','shield','heartPlus','starPlus'],rank:['chev1','chev2','rocket','crown','carrotStar','shield','starPlus','compass','crew','bolt']};
const B0={name:'',rule:'',story:'',art:'starTrail',upload:null,focal:[50,50],disc:0};
const BE={...B0,name:'Zawsze na pokładzie',rule:'Co najmniej 26 marchewek za obecność',story:'Rekrut nigdy nie opuścił statku',art:'rocket',disc:3};
const R0={name:'',art:'crown',upload:null,focal:[50,50],min:100,disc:7};
const RE={...R0,name:'Pilot Marcheton-7',art:'rocket',min:80,disc:5};
const TOT=[60,26,23,34,25,41,18,52,37,12,29,44];
const clone=o=>JSON.parse(JSON.stringify(o));
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',kind:'badge',mode:'create',pv:'won',f:clone(B0),orig:'',err:{},dlg:null};
S.orig=JSON.stringify(S.f);
const dirty=()=>JSON.stringify(S.f)!==S.orig, isB=()=>S.kind==='badge', noun=()=>isB()?'odznakę':'rangę';
const art=()=>S.f.art==='upload'?`<img src="${S.f.upload}" alt="" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:${S.f.focal[0]}% ${S.f.focal[1]}%">`:glyph(S.f.art);
const err=k=>S.err[k]?`<p class="err" id="e-${k}">${icon('alert')}${S.err[k]}</p>`:'';
const inp=(k,v,ph,a='')=>`<div class="inp${S.err[k]?' bad':''}"><input id="f-${k}" data-f="${k}" value="${esc(v)}" placeholder="${ph}"${S.err[k]?` aria-invalid="true" aria-describedby="e-${k}"`:''} ${a}></div>`;
const numInp=(k,v,lab)=>`<div class="price-row"><div class="inp num${S.err[k]?' bad':''}"><input id="f-${k}" type="number" min="0" data-f="${k}" value="${v}" aria-label="${lab}"${S.err[k]?` aria-invalid="true" aria-describedby="e-${k}"`:''}></div>`;
function imageField(){const f=S.f;return `<div class="fld"><p class="lbl">Grafika</p><div class="pz-grid" role="radiogroup" aria-label="Gotowe grafiki">${PRE[S.kind].map(k=>`<button class="pz glp k-${S.kind}" role="radio" aria-checked="${f.art===k}" data-act="art" data-v="${k}" aria-label="Grafika ${k}"><i>${glyph(k)}</i></button>`).join('')}${f.upload?`<button class="pz" role="radio" aria-checked="${f.art==='upload'}" data-act="art" data-v="upload" aria-label="Twoja grafika"><i style="background-image:url('${f.upload}')"></i></button>`:''}</div>
 <div class="drop"><span class="drop-ic">${icon('upload')}</span><span><b>Albo wgraj własną grafikę</b><small>JPG lub PNG, najlepiej co najmniej 400 px.</small></span><label class="btn sec sm">Wybierz plik<input type="file" accept="image/*" data-file="1" class="sr"></label></div>
 ${f.art==='upload'?`<div class="fld"><p class="lbl">Najważniejszy fragment</p><div class="focal"><img src="${f.upload}" alt="Podgląd grafiki" data-act="focal"><span class="mk" style="left:${f.focal[0]}%;top:${f.focal[1]}%"></span></div><span class="hint">Kliknij obraz, żeby wskazać, co ma zostać widoczne po przycięciu.</span></div>`:''}</div>`;}
/* ---------- rank ladder logic ---------- */
function ladder(){const L=RANKS.map((r,i)=>({id:'r'+i,name:r.name,min:r.min,disc:r.disc,glyph:r.glyph}));const me={id:S.mode==='edit'?'r2':'new',name:S.f.name||'Nowa ranga',min:+S.f.min||0,disc:+S.f.disc||0,glyph:S.f.art,up:S.f.art==='upload',me:1};
 if(S.mode==='edit')L[2]=me;else L.push(me);L.sort((a,b)=>a.min-b.min||(a.me?1:-1));L.forEach(x=>x.clash=L.some(y=>y!==x&&y.min===x.min));return L;}
const rankOf=(t,L)=>L.reduce((r,x)=>t>=x.min&&(!r||x.min>=r.min)?x:r,null);
function impact(){const before=RANKS.map((r,i)=>({id:'r'+i,min:r.min})),after=ladder();let up=0,down=0,got=0;
 TOT.forEach(t=>{const a=rankOf(t,before),b=rankOf(t,after);if(b&&b.me)got++;if(a&&b&&a.id!==b.id){b.min>a.min?up++:down++;}});return{up,down,got};}
function rankWarn(){const L=ladder(),me=L.find(x=>x.me),lo=L.filter(x=>!x.me&&x.min<me.min).pop(),hi=L.find(x=>!x.me&&x.min>me.min),w=[];
 if(lo&&me.disc<lo.disc)w.push(`Ranga niżej (${lo.name}) daje −${lo.disc}%, a ta tylko −${me.disc}%. Awans obniżyłby zniżkę.`);
 if(hi&&me.disc>hi.disc)w.push(`Ranga wyżej (${hi.name}) daje tylko −${hi.disc}%. Awans na nią obniżyłby zniżkę.`);
 return w.map(t=>`<p class="warn2">${icon('alert')}<span>${esc(t)}</span></p>`).join('');}
function impactText(){const x=impact(),n=x.up+x.down;
 if(S.mode==='create')return x.got?`Od razu dostanie ją <b>${x.got} ${pl(x.got,'student','studentów','studentów')}</b>. Pozostali zobaczą ją jako kolejny cel.`:'Na razie nikt nie ma tylu zebranych. Studenci zobaczą ją jako kolejny cel.';
 return n?`Po zapisaniu <b>${n} ${pl(n,'student zmieni','studentów zmieni','studentów zmieni')} rangę</b>${x.up?`: ${x.up} awansuje`:''}${x.down?`${x.up?',':':'} ${x.down} spadnie`:''}.`:'Żaden student nie zmieni rangi.';}
/* ---------- forms ---------- */
function formBadge(){const f=S.f;return `${S.mode==='edit'?`<p class="info">${icon('users')}<span><b>4 studentów ma tę odznakę.</b> Zmiana zniżki od razu obejmie ich kolejne zakupy.</span></p>`:''}
 <div class="fsec"><h2 class="h3">Karta odznaki</h2><p class="hint">Tak odznaka wygląda w talii studenta i w oknie przyznawania.</p>
 <div class="fld"><label for="f-name">Nazwa</label>${inp('name',f.name,'np. Perfekcyjny Lot','maxlength="50" autocomplete="off"')}${err('name')}</div>
 <div class="fld"><label for="f-rule">Jak zdobyć</label><div class="inp${S.err.rule?' bad':''}"><textarea id="f-rule" data-f="rule" rows="2" style="font:400 15px/1.5 var(--f-text);min-height:72px" placeholder="np. Co najmniej 3 wejściówki z rzędu bez błędów"${S.err.rule?' aria-invalid="true" aria-describedby="e-rule"':''}>${esc(f.rule)}</textarea></div>${err('rule')}<span class="hint">Studenci widzą to na odwrocie odznaki, której jeszcze nie mają. Pisz konkretnie.</span></div>
 <div class="fld"><label for="f-story">Opis fabularny <small>(opcjonalnie)</small></label><div class="inp"><textarea id="f-story" data-f="story" rows="2" style="min-height:72px" placeholder="np. Lot bez najmniejszej rysy">${esc(f.story)}</textarea></div></div>${imageField()}</div>
 <div class="fsec"><h2 class="h3">Zniżka w sklepie</h2><p class="hint">Działa tylko na przedmioty, które ją uwzględniają. Ustawiasz to w formularzu przedmiotu.</p>
 <div class="fld">${numInp('disc',f.disc,'Zniżka w procentach')}<span class="unit">%</span></div>${err('disc')}</div>
 ${S.mode==='edit'?`<p class="lbl" style="margin-top:14px">Uwzględniają ją</p><ul class="uses">${[['Bezpieczna poprawa','shield'],['Zaliczenie wejściówki','paperCheck']].map(([n,g])=>`<li><span class="card item mc"><span class="card-f"><span class="card-i">${glyph(g)}</span></span></span>${n}</li>`).join('')}</ul>`:'<p class="expl">Na razie żaden przedmiot jej nie uwzględnia.</p>'}</div>
 ${S.mode==='edit'?`<div class="fsec"><h2 class="h3">Usuwanie</h2><p class="hint">Odznaka zniknie z listy i z okna przyznawania. Studenci, którzy ją mają, zachowają ją w historii.</p><div class="rowb" style="margin-top:12px"><button class="btn sec" data-act="archive">${icon('trash')}Usuń odznakę</button></div></div>`:''}`;}
function formRank(){const f=S.f;return `${S.mode==='edit'?`<p class="info">${icon('users')}<span><b>2 studentów ma tę rangę.</b> Zmiana progu może przesunąć studentów w górę lub w dół. Podgląd obok pokazuje skutki.</span></p>`:''}
 <div class="fsec"><h2 class="h3">Karta rangi</h2><p class="hint">Tak ranga wygląda na stronie grupy i w rankingu.</p>
 <div class="fld"><label for="f-name">Nazwa</label>${inp('name',f.name,'np. Admirał Floty','maxlength="40" autocomplete="off"')}${err('name')}</div>${imageField()}</div>
 <div class="fsec"><h2 class="h3">Próg i nagroda</h2><p class="hint">Ranga zależy od łącznie zebranej waluty, więc wydawanie jej nie obniża rangi.</p>
 <div class="row2"><div class="fld"><label for="f-min">Wymagane zebrane</label>${numInp('min',f.min,'Wymagane zebrane')}<span class="tok" style="--s:30px"><span><svg viewBox="0 0 24 24">${CI.carrot}</svg></span></span></div>${err('min')}</div>
 <div class="fld"><label for="f-disc">Zniżka w sklepie</label>${numInp('disc',f.disc,'Zniżka w procentach')}<span class="unit">%</span></div>${err('disc')}</div></div>
 <p class="expl" id="imp">${impactText()}</p><div id="warns">${rankWarn()}</div></div>
 ${S.mode==='edit'?`<div class="fsec"><h2 class="h3">Usuwanie</h2><p class="hint">Studenci z tą rangą spadną do rangi niżej. Przedmioty, które jej wymagają, trzeba będzie przypisać do innej rangi.</p><div class="rowb" style="margin-top:12px"><button class="btn sec" data-act="del">${icon('trash')}Usuń rangę</button></div></div>`:''}`;}
/* ---------- previews ---------- */
function pvBadge(){const f=S.f,nm=esc(f.name||'Nazwa odznaki'),ph=f.name?'':' ph';
 return `<details class="pvd" open><summary>Podgląd karty ${icon('chevDown')}</summary><section class="panel pv"><h3>Tak zobaczą to studenci</h3>
 <div class="seg2" role="group" aria-label="Strona karty">${[['won','Zdobyta'],['lost','Jeszcze niezdobyta']].map(([k,l])=>`<button data-act="pv" data-v="${k}" aria-pressed="${S.pv===k}">${l}</button>`).join('')}</div>
 <div class="pvflip"><article class="card badge flip${S.pv==='lost'?' down':''}"><div class="flip-in">
  <div class="face front"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name${ph}">${nm}</h3></div><div class="art">${art()}</div><p class="rules${f.rule?'':' ph'}">${esc(f.rule||'Jak zdobyć…')}</p>${f.story?`<p class="flavor">${esc(f.story)}</p>`:''}${+f.disc?`<div class="card-foot"><span class="tag tag-disc">−${+f.disc}% w sklepie</span></div>`:''}</div></div></div>
  <div class="face back"><div class="card-f"><div class="card-i back-i"><div class="back-art">${MARK}</div><h3 class="card-name${ph}">${nm}</h3><p class="how"><span>Jak zdobyć</span>${esc(f.rule||'Jak zdobyć…')}</p></div></div></div>
 </div></article></div></section>
 <section class="panel pv"><h3>W oknie przyznawania</h3><div class="thumbrow"><span class="card badge mc"><span class="card-f"><span class="card-i">${art()}</span></span></span><span><b>${nm}</b><span class="small">${esc(f.story||f.rule||'')}</span></span></div></section></details>`;}
function pvRank(){const f=S.f,L=ladder();
 return `<details class="pvd" open><summary>Podgląd rangi ${icon('chevDown')}</summary><section class="panel pv"><h3>Karta rangi</h3><div class="pvflip"><article class="card gold full"><div class="card-f"><div class="card-i"><div class="card-top"><h3 class="card-name${f.name?'':' ph'}">${esc(f.name||'Nazwa rangi')}</h3></div><div class="art">${art()}</div><p class="rules">Wymagane: ${+f.min||0} zebranych.${+f.disc?` Daje −${+f.disc}% w sklepie.`:''}</p><div class="card-foot" style="min-height:0"></div></div></div></article></div></section>
 <section class="panel pv"><h3>Drabinka rang</h3><ol class="ladder">${L.map(x=>`<li class="lad${x.me?' new':''}${x.clash?' clash':''}"><span class="card gold mc"><span class="card-f"><span class="card-i">${x.up?art():glyph(x.glyph)}</span></span></span><span><b>${esc(x.name)}${x.me?' <small>(ta ranga)</small>':''}</b><small>${x.disc?`−${x.disc}% w sklepie`:'Ranga startowa'}</small></span><span class="v">od ${x.min}</span></li>`).join('')}</ol></section></details>`;}
/* ---------- shell ---------- */
function wbar(){const d=dirty();return `<div class="panel wbar"><button class="linkbtn" data-act="cancel">Anuluj</button><span class="sp"></span>${S.mode==='edit'?`<span class="k" id="dk">${d?'Niezapisane zmiany':'Brak zmian'}</span><button class="btn" data-act="save" id="sv"${d?'':' disabled'}>Zapisz zmiany</button>`:`<button class="btn" data-act="save">${icon('plus')}Dodaj ${noun()}</button>`}</div>`;}
function refresh(){const p=app.querySelector('.pcol');if(p){const o=p.querySelector('.pvd').open;p.innerHTML=isB()?pvBadge():pvRank();p.querySelector('.pvd').open=o;}
 const set=(id,h)=>{const e=app.querySelector('#'+id);if(e)e.innerHTML=h;};if(!isB()){set('imp',impactText());set('warns',rankWarn());}
 const d=dirty(),k=app.querySelector('#dk'),b=app.querySelector('#sv');if(k)k.textContent=d?'Niezapisane zmiany':'Brak zmian';if(b)b.disabled=!d;}
function layer(){const L=app.querySelector('#layer');if(!S.dlg){L.innerHTML='';L.classList.remove('on');return;}L.classList.add('on');
 const del=S.dlg==='delete',x=impact();
 L.innerHTML=`<div class="ovl" data-act="close"><div class="dlg" role="dialog" aria-modal="true" aria-labelledby="dt" data-act="noop"><div class="dlg-in"><span class="grab"></span>
 <h2 class="h2" id="dt">${del?(isB()?`Usunąć odznakę „${esc(S.f.name)}”?`:`Usunąć rangę ${esc(S.f.name)}?`):'Odrzucić zmiany?'}</h2>
 ${del?`<p>${isB()?'Studenci, którzy mają tę odznakę, zachowają ją w historii, ale nikt nowy jej nie dostanie.':'Studenci z tą rangą spadną do niższej.'}</p><p class="warn">${icon('alert')}Przedmioty „0.5% oceny” i „Bezpieczna poprawa trzech wejściówek” wymagają tej rangi. Po usunięciu wybierzesz dla nich inną.</p>`:`<p>Niezapisane zmiany zostaną utracone.</p>`}
 <div class="dlg-b"><button class="btn sec" data-act="close" data-focus>${del?'Anuluj':'Wróć do edycji'}</button><button class="btn" data-act="${del?'dodel':'discard'}">${del?(isB()?'Usuń odznakę':'Usuń rangę'):'Odrzuć zmiany'}</button></div></div></div></div>`;L.querySelector('[data-focus]').focus();}
function validate(){const f=S.f;S.err={};if(!f.name.trim())S.err.name=isB()?'Podaj nazwę odznaki.':'Podaj nazwę rangi.';
 if(isB()){if(!f.rule.trim())S.err.rule='Napisz, jak zdobyć tę odznakę.';}
 else{const c=ladder().find(x=>!x.me&&x.min===+f.min);if(!(+f.min>=1))S.err.min='Próg musi wynosić co najmniej 1. Próg 0 ma ranga startowa.';else if(c)S.err.min=`Ranga ${c.name} ma już próg ${c.min}. Wybierz inny.`;}
 if(!(+f.disc>=0&&+f.disc<=100))S.err.disc='Zniżka musi mieścić się między 0 a 100%.';return !Object.keys(S.err).length;}
const ACT={noop(){},close(){S.dlg=null;layer();},theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},
 art(a){S.f.art=a.dataset.v;render(true);},
 pv(a){S.pv=a.dataset.v;const c=app.querySelector('.pvflip .flip');if(c)c.classList.toggle('down',S.pv==='lost');app.querySelectorAll('[data-act=pv]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.v===S.pv));},
 focal(a,e){const r=a.getBoundingClientRect();S.f.focal=[Math.round((e.clientX-r.left)/r.width*100),Math.round((e.clientY-r.top)/r.height*100)];const k=app.querySelector('.mk');k.style.left=S.f.focal[0]+'%';k.style.top=S.f.focal[1]+'%';refresh();},
 save(){if(!validate()){render(true);const f=app.querySelector('[aria-invalid="true"]');if(f)f.focus();return;}
  if(S.mode==='edit'){S.orig=JSON.stringify(S.f);render(true);toast(icon('check')+'Zapisano zmiany.');}else toast(icon('check')+`Dodano ${noun()} „${esc(S.f.name)}”.`);},
 cancel(){if(dirty()){S.dlg='discard';layer();}else hint('Would return to the list.');},discard(){S.f=JSON.parse(S.orig);S.dlg=null;S.err={};render(true);},
 noop2(){}};
ON('input',e=>{const t=e.target,k=t.dataset.f;if(!k)return;S.f[k]=t.type==='number'?(t.value===''?'':Math.max(0,parseInt(t.value,10)||0)):t.value;
 if(S.err[k]){delete S.err[k];t.parentNode.classList.remove('bad');t.removeAttribute('aria-invalid');const m=app.querySelector('#e-'+k);if(m)m.remove();}refresh();});
ON('change',e=>{const t=e.target;if(t.dataset.file&&t.files[0]){const r=new FileReader();r.onload=()=>{S.f.upload=r.result;S.f.art='upload';S.f.focal=[50,50];render(true);};r.readAsDataURL(t.files[0]);}});
DON('keydown',e=>{if(e.key==='Escape'&&S.dlg)ACT.close();});
function load(kind,mode){S.kind=kind;S.mode=mode;S.f=clone(kind==='badge'?(mode==='edit'?BE:B0):(mode==='edit'?RE:R0));S.orig=JSON.stringify(S.f);S.err={};S.pv='won';S.dlg=null;render();}

const fromBadge = b => ({...clone(B0), id: b.id, name: b.name, rule: b.rule, story: b.flavor, art: b.glyph, disc: b.disc});
const fromRank = (r, i) => ({...clone(R0), idx: i, name: r.name, art: r.glyph, min: r.min, disc: r.disc});

delete ACT.theme;
ACT.cancel = function () { if (dirty()) { S.dlg = 'discard'; layer(); } else nav(isB() ? 't/badges' : 't/ranks'); };
ACT.discard = function () { S.f = JSON.parse(S.orig); S.dlg = null; S.err = {}; nav(isB() ? 't/badges' : 't/ranks'); };
ACT.save = function () {
  if (!validate()) { render(true); const f = app.querySelector('[aria-invalid="true"]'); if (f) f.focus(); return; }
  const f = S.f;
  if (isB()) {
    if (S.mode === 'edit') {
      const b = BADGE[f.id]; Object.assign(b, {name: f.name.trim(), rule: f.rule.trim(), flavor: f.story.trim(), glyph: f.art, disc: +f.disc});
      nav('t/badges'); toast(icon('check') + `Zapisano odznakę „${esc(b.name)}”.`);
    } else {
      const b = {id: 'b' + Date.now().toString(36), name: f.name.trim(), rule: f.rule.trim(), flavor: f.story.trim(), glyph: f.art, disc: +f.disc};
      BADGES.push(b); BADGE[b.id] = b;
      nav('t/badges'); toast(icon('check') + `Dodano odznakę „${esc(b.name)}”.`);
    }
  } else {
    const data = {name: f.name.trim(), min: +f.min, disc: +f.disc, glyph: f.art};
    if (S.mode === 'edit') Object.assign(RANKS[f.idx != null ? f.idx : 2], data); else RANKS.push(data);
    RANKS.sort((a, b) => a.min - b.min);
    nav('t/ranks'); toast(icon('check') + (S.mode === 'edit' ? `Zapisano rangę „${esc(data.name)}”.` : `Dodano rangę „${esc(data.name)}”.`));
  }
};
ACT.archive = function () { S.dlg = 'delete'; layer(); };
ACT.del = function () { S.dlg = 'delete'; layer(); };
ACT.dodel = function () {
  S.dlg = null;
  if (isB()) {
    const b = BADGE[S.f.id], i = BADGES.indexOf(b); if (i > -1) BADGES.splice(i, 1);
    nav('t/badges'); toast(icon('check') + `Usunięto odznakę „${esc(b.name)}”. Studenci, którzy ją mają, zachowują ją w historii.`);
  } else {
    const i = S.f.idx != null ? S.f.idx : 2, r = RANKS[i];
    if (i > 0) RANKS.splice(i, 1);
    nav('t/ranks'); toast(icon('check') + `Usunięto rangę „${esc(r.name)}”.`);
  }
};

reg('br', {
  act: ACT, layer,
  closeLayer() { S.dlg = null; },
  setView(v, o) {
    const [kind, mode] = v.split('-');
    S.kind = kind; S.mode = mode === 'edit' ? 'edit' : 'create';
    if (S.mode === 'edit') {
      if (kind === 'badge') { const b = (o && o.i && BADGE[o.i]) || BADGES[1]; S.f = fromBadge(b); }
      else { const i = o && o.i != null && RANKS[+o.i] ? +o.i : 2; S.f = fromRank(RANKS[i], i); }
    } else S.f = clone(kind === 'badge' ? B0 : R0);
    S.orig = JSON.stringify(S.f); S.err = {}; S.pv = kind === 'badge' ? 'won' : 'won'; S.dlg = null;
  },
  page() {
    const b = isB(), e = S.mode === 'edit';
    setRoute(b ? (e ? 't/badge-edit' : 't/badge-new') : (e ? 't/rank-edit' : 't/rank-new'));
    const crumb = b ? 'Odznaki' : 'Rangi', to = b ? 't/badges' : 't/ranks';
    const title = e ? (b ? 'Edytuj odznakę' : 'Edytuj rangę') : (b ? 'Nowa odznaka' : 'Nowa ranga');
    return `<div class="page">
      <section class="panel phead" style="display:block"><p class="crumbs"><a href="#/${to}" data-act="nav" data-to="${to}">${crumb}</a>${icon('chevRight')}<span>${e ? esc(JSON.parse(S.orig).name) : title}</span></p><h1>${title}</h1><p class="lead">${b ? 'Podgląd obok pokazuje obie strony karty: zdobytą i jeszcze niezdobytą.' : 'Podgląd obok pokazuje, gdzie ranga trafi na drabince i ilu studentów obejmie.'}</p></section>
      <div class="wiz"><section class="panel fcol">${b ? formBadge() : formRank()}</section><aside class="pcol" aria-label="Podgląd">${b ? pvBadge() : pvRank()}</aside></div>
      <div style="margin-bottom:14px">${wbar()}</div></div>`;
  }
});
})();
