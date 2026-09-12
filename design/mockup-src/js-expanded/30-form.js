/* ===== module: form (new group wizard, from t/form.html) ===== */
(() => {
const ON = (t, f) => on('form', t, f), DON = (t, f) => ondoc('form', t, f);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl=(n,a,b,c)=>{n=Math.abs(n);if(n===1)return a;const d=n%10,h=n%100;return d>=2&&d<=4&&(h<12||h>14)?b:c;};
const fs=d=>`<path class="f" d="${d}"/><path d="${d}"/>`;
const IC={home:'<path d="M3 11l9-7 9 7v10h-6v-6H9v6H3z"/>',cards:'<path d="M8 3h12v15H8z"/><path d="M4 7v14h12"/>',bell:'<path d="M6 16v-6a6 6 0 0 1 12 0v6l2 2H4z"/><path d="M10 21h4"/>',
sun:'<path d="M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10z"/><path d="M12 1v3M12 20v3M1 12h3M20 12h3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/>',moon:'<path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5z"/>',
plus:'<path d="M12 5v14M5 12h14"/>',minus:'<path d="M5 12h14"/>',check:'<path d="M5 12.5l4.5 4.5L19 7"/>',chevRight:'<path d="M9 6l6 6-6 6"/>',chevLeft:'<path d="M15 6l-6 6 6 6"/>',
upload:'<path d="M12 16V4M7 9l5-5 5 5M4 16v4h16v-4"/>',x:'<path d="M6 6l12 12M18 6L6 18"/>',undo:'<path d="M9 14L4 9l5-5"/><path d="M4 9h11a5 5 0 0 1 0 10h-3"/>',
alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',rank:'<path d="M5 12l7-6 7 6"/><path d="M5 19l7-6 7 6"/>',badge:'<path d="M7 3h10l3 5-8 8-8-8z"/><path d="M8 13l-2 8 6-3 6 3-2-8"/>',
bag:'<path d="M4 8h16l-1 13H5z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/>',grid:'<path d="M3 4h18v16H3zM3 10h18M3 15h18M9 4v16M15 4v16"/>',copy:'<path d="M8 8h12v12H8z"/><path d="M4 16V4h12"/>',
qr:'<path d="M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h3v3h-3zM18 18h3v3h-3zM14 20h2M20 14v2"/>',users:'<path d="M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"/><path d="M2 21v-2a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v2"/>',overview:'<path d="M3 3h8v8H3zM13 3h8v5h-8zM13 10h8v11h-8zM3 13h8v8H3z"/>'};
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const CV={carrot:fs('M15.5 7.5L2.5 21.5l14.5-11z')+'<path d="M16 7.5l1-5.5M17 9l5.5-1.5M17.3 7.2L21.5 3"/>',
 coin:fs('M8 3h8l5 5v8l-5 5H8l-5-5V8z')+'<path d="M12 7v10M14.5 9.5h-4a1.5 1.5 0 0 0 0 3h3a1.5 1.5 0 0 1 0 3h-4"/>',
 gem:fs('M6 4h12l4 6-10 11L2 10z')+'<path d="M2 10h20M9 4l3 17M15 4l-3 17"/>',pearl:fs('M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16z')+'<path d="M8.4 10.2a4 4 0 0 1 3.4-2.6"/>'};
const CVN={carrot:'Marchewka',coin:'Moneta',gem:'Klejnot',pearl:'Perła'};
const svgUrl=s=>`url('data:image/svg+xml;charset=utf-8,${encodeURIComponent(s)}')`;
const sv=b=>svgUrl(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice">${b}</svg>`);
const ART={rabbits:{l:'Kosmos (zdjęcie)',u:"url('__RABBITS__')"},
 castle:{l:'Zamek',u:sv('<rect width="160" height="90" fill="#2B2440"/><circle cx="126" cy="22" r="9" fill="#F2E3B3"/><path d="M34 90V46h8v-6h6v6h8V30h6v-6h6v6h6v16h8v-6h6v6h8v44z" fill="#6E6480"/><path d="M72 90V72h16v18z" fill="#2B2440"/><rect y="84" width="160" height="6" fill="#3E3553"/>')},
 waves:{l:'Morze',u:sv('<rect width="160" height="90" fill="#0E4F5C"/><g fill="none" stroke-width="5"><path d="M-10 34q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#2F9DA3"/><path d="M-10 54q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#5CCFC6"/><path d="M-10 74q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#2F9DA3"/></g>')},
 tables:{l:'Tabele',u:sv('<rect width="160" height="90" fill="#35245E"/><g fill="none" stroke="#A58EE6" stroke-width="4"><path d="M18 18h50v54H18zM18 36h50M18 54h50M42 18v54M92 26h50v38H92zM92 44h50M116 26v38M68 45h24"/></g>')},
 flow:{l:'Algorytm',u:sv('<rect width="160" height="90" fill="#17492F"/><g fill="none" stroke="#7CD6A0" stroke-width="4"><path d="M14 36h32v18H14zM114 36h32v18h-32zM80 22l16 23-16 23-16-23zM46 45h18M96 45h18"/></g>')},
 brackets:{l:'Kod',u:sv('<rect width="160" height="90" fill="#6B2E0E"/><g fill="none" stroke="#FFB27A" stroke-width="6"><path d="M54 22L30 45l24 23M106 22l24 23-24 23M90 16L70 74"/></g>')}};
const PACKS={neutral:{l:'Neutralny',d:'Bez fabularnego klimatu. Pasuje do każdego przedmiotu.',ranks:['Nowicjusz','Uczeń','Adept','Ekspert','Mistrz'],badges:['Bez skazy','Stała obecność','Pomocna dłoń','Iskra ciekawości','Seria sukcesów','Głos grupy']},
 fantasy:{l:'Fantasy',d:'Zamki, zakony i rycerskie tytuły.',ranks:['Giermek','Rycerz','Kasztelan','Hetman','Król'],badges:['Czysta klinga','Wierna straż','Tarcza drużyny','Księga mądrości','Pasmo zwycięstw','Bard drużyny']},
 scifi:{l:'Sci-fi',d:'Statki, załogi i kosmiczne misje.',ranks:['Kadet','Pilot','Nawigator','Komandor','Admirał'],badges:['Czysty lot','Zawsze na pokładzie','Mechanik załogi','Sygnał z kosmosu','Seria misji','Głos floty']}};
const BRULES=['Pierwsza wejściówka bez błędów','Obecność na wszystkich zajęciach w miesiącu','Co najmniej 3 razy pomoc innym','Co najmniej 3 ciekawe uwagi','3 wejściówki z rzędu ≥ średnia grupy','Wyjaśnienie trudnego zadania całej grupie'];
const ITEMS0=[['+5 minut do wejściówki',15],['Konsultacja',15],['Poprawa wejściówki',20],['Bezpieczna poprawa',30],['Usprawiedliwienie',12],['1up: odzyskanie życia',40]];
const CATS0=[['Obecność',2],['Punktualność',2],['Wejściówka zaliczona',1],['Wejściówka ≥ średnia grupy',1],['Zgłoszenie do zadania',1],['Zadanie zrobione poprawnie',1],['Pomoc innym',1],['Ciekawa uwaga',1]];
const DISC=[0,3,5,10,15],RF=[0,.15,.35,.6,.85];
const fresh=()=>({step:0,max:0,done:false,name:'',story:'',art:null,upload:null,focal:[50,50],cur:{n1:'',n2:'',n5:'',icon:'carrot',upload:null,coin:false,px:false},lives:3,ranking:true,path:null,pack:'neutral',classes:12,excl:{},over:{},err:{}});
let S=Object.assign({theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop'},fresh());
const STEPS=()=>['Grupa i opowieść','Waluta i życia','Jak zaczynasz',S.path==='manual'?'Podsumowanie':'Przegląd zestawu'];
const artUrl=()=>S.art==='upload'?`url('${S.upload}')`:S.art?ART[S.art].u:'none';
const artStyle=()=>`background-image:${artUrl()};background-position:${S.focal[0]}% ${S.focal[1]}%`;
const curImg=()=>S.cur.icon==='upload'?`<img src="${S.cur.upload}" alt=""${S.cur.px?' class="px"':''}>`:`<svg viewBox="0 0 24 24">${CV[S.cur.icon]}</svg>`;
const tok=s=>S.cur.icon==='upload'&&S.cur.coin?`<span class="bleed" style="--s:${s}px">${curImg()}</span>`:`<span class="tok" style="--s:${s}px"><span>${curImg()}</span></span>`;
const f1=()=>S.cur.n1||'Złota Marchewka',f2=()=>S.cur.n2||f1(),f5=()=>S.cur.n5||f2();
function gen(){const P=PACKS[S.pack],E=6*S.classes,r5=x=>Math.round(x/5)*5,o=id=>S.over[id];
 return{ranks:P.ranks.map((n,i)=>({id:'r'+i,name:n,val:i?(o('r'+i)??r5(RF[i]*E)):0,disc:DISC[i]})),badges:P.badges.map((n,i)=>({id:'b'+i,name:n,rule:BRULES[i]})),
  items:ITEMS0.map(([n,p],i)=>({id:'i'+i,name:n,val:o('i'+i)??Math.max(1,Math.round(p*S.classes/12))})),cats:CATS0.map(([n,p],i)=>({id:'c'+i,name:n,val:p}))};}
const err=k=>S.err[k]?`<p class="err" id="e-${k}">${icon('alert')}${S.err[k]}</p>`:'';
const inp=(k,v,ph,a='')=>`<div class="inp${S.err[k]?' bad':''}"><input id="f-${k}" data-f="${k}" value="${esc(v)}" placeholder="${ph}"${S.err[k]?` aria-invalid="true" aria-describedby="e-${k}"`:''} ${a}></div>`;

function stepper(){return `<nav class="stepper" aria-label="Kroki">${STEPS().map((l,i)=>{const st=i===S.step?'on':i<S.step||i<=S.max?'ok':'';return `<button class="stp ${st}" data-act="goto" data-i="${i}"${i>S.max?' disabled':''}${i===S.step?' aria-current="step"':''}><span class="n">${st==='ok'&&i!==S.step?icon('check'):i+1}</span><span>${l}</span></button>`;}).join('')}</nav>`;}
function step0(){return `<div class="fsec"><h2 class="h3">Nazwa i opowieść</h2><p class="hint">Studenci zobaczą je na liście grup i na stronie grupy.</p>
 <div class="fld"><label for="f-name">Nazwa grupy</label>${inp('name',S.name,'np. Zakon Algorytmów','maxlength="60" autocomplete="off"')}${err('name')}</div>
 <div class="fld"><label for="f-story">Opowieść <small>(opcjonalnie)</small></label><div class="inp"><textarea id="f-story" data-f="story" rows="4" placeholder="Dawno, dawno temu…">${esc(S.story)}</textarea></div><span class="hint">Krótki wstęp fabularny. Zmienisz go w każdej chwili.</span></div></div>
 <div class="fsec"><h2 class="h3">Grafika grupy</h2><p class="hint">Pojawia się na karcie grupy, w panelu bocznym i jako tło stołu.</p>
 <div class="pz-grid" role="radiogroup" aria-label="Gotowe grafiki">${Object.entries(ART).map(([k,a])=>`<button class="pz" role="radio" aria-checked="${S.art===k}" aria-label="${a.l}" title="${a.l}" data-act="art" data-v="${k}"><i style="background-image:${a.u}"></i></button>`).join('')}${S.upload?`<button class="pz" role="radio" aria-checked="${S.art==='upload'}" aria-label="Twoja grafika" data-act="art" data-v="upload"><i style="background-image:url('${S.upload}')"></i></button>`:''}</div>
 <div class="drop"><span class="drop-ic">${icon('upload')}</span><span><b>Albo wgraj własną grafikę</b><small>JPG lub PNG, najlepiej co najmniej 1200 px szerokości.</small></span><label class="btn sec sm">Wybierz plik<input type="file" accept="image/*" data-file="art" class="sr"></label></div>
 ${S.art?`<div class="fld"><p class="lbl">Najważniejszy fragment</p><div class="focal"><img src="${S.art==='upload'?S.upload:''}" alt="Podgląd grafiki grupy" data-act="focal" style="${S.art==='upload'?'':`aspect-ratio:16/9;background:${ART[S.art].u} center/cover`}"><span class="mk" style="left:${S.focal[0]}%;top:${S.focal[1]}%"></span></div><span class="hint">Kliknij obraz, żeby wskazać, co ma zostać widoczne po przycięciu do karty i miniatury.</span></div>`:''}</div>`;}
function step1(){return `<div class="fsec"><h2 class="h3">Nazwa waluty</h2><p class="hint">Aplikacja odmienia nazwę w zdaniach, więc podaj ją w trzech formach.</p>
 <div class="row3"><div class="fld"><label for="f-n1">Przy liczbie 1</label>${inp('n1',S.cur.n1,'Złota Moneta')}</div><div class="fld"><label for="f-n2">Przy 2, 3, 4</label>${inp('n2',S.cur.n2,'Złote Monety')}</div><div class="fld"><label for="f-n5">Przy 5 i więcej</label>${inp('n5',S.cur.n5,'Złotych Monet')}</div></div>${err('n1')}</div>
 <div class="fsec"><h2 class="h3">Ikona waluty</h2><p class="hint">Widoczna przy stanie konta, w zakupach i na karcie waluty. Na małych etykietach cen pokazujemy samą liczbę.</p>
 <div class="pz-grid" role="radiogroup" aria-label="Gotowe ikony">${Object.keys(CV).map(k=>`<button class="pz cur" role="radio" aria-checked="${S.cur.icon===k}" aria-label="${CVN[k]}" title="${CVN[k]}" data-act="cicon" data-v="${k}"><i><svg viewBox="0 0 24 24">${CV[k]}</svg></i></button>`).join('')}${S.cur.upload?`<button class="pz cur" role="radio" aria-checked="${S.cur.icon==='upload'}" aria-label="Twoja ikona" data-act="cicon" data-v="upload"><i><img src="${S.cur.upload}" alt=""${S.cur.px?' class="px"':''}></i></button>`:''}</div>
 <div class="drop"><span class="drop-ic">${icon('upload')}</span><span><b>Albo wgraj własną ikonę</b><small>Najlepiej PNG z przezroczystym tłem, co najmniej 128 px.</small></span><label class="btn sec sm">Wybierz plik<input type="file" accept="image/*" data-file="cur" class="sr"></label></div>
 ${S.cur.icon==='upload'?`<div class="swrow"><button class="sw" role="switch" aria-checked="${S.cur.coin}" data-act="coin" aria-labelledby="l-coin"><i></i></button><span><b id="l-coin">Moja ikona to już moneta</b><span class="hint">Pokażemy ją bez złotej ramki. Sprawdź podgląd obok.</span></span></div>`:''}</div>
 <div class="fsec"><h2 class="h3">Życia i ranking</h2>
 <div class="fld"><p class="lbl" id="l-lives">Życia na start</p><div class="nstep" role="group" aria-labelledby="l-lives"><button data-act="num" data-k="lives" data-d="-1" aria-label="Mniej żyć">${icon('minus')}</button><output aria-live="polite">${S.lives}</output><button data-act="num" data-k="lives" data-d="1" aria-label="Więcej żyć">${icon('plus')}</button></div><span class="hint">Przy 0 życiach student kupi tylko przedmioty oznaczone jako dostępne przy 0 życiach.</span></div>
 <div class="swrow"><button class="sw" role="switch" aria-checked="${S.ranking}" data-act="ranking" aria-labelledby="l-rk"><i></i></button><span><b id="l-rk">Pokazuj ranking studentom</b><span class="hint">Możesz go ukryć w każdej chwili.</span></span></div></div>`;}
function step2(){const o=(v,h)=>`<button class="opt" role="radio" aria-checked="${S.path===v}" data-act="path" data-v="${v}">${h}</button>`;
 return `<div class="fsec"><h2 class="h3">Jak chcesz zacząć?</h2><p class="hint">Obie drogi dają pełną grupę. Wszystko zmienisz później.</p>
 <div class="opts" role="radiogroup" aria-label="Sposób startu">${o('quick','<span class="tag tag-disc">Polecane na pierwszą grupę</span><b>Szybki start</b><span>Gotowe rangi, odznaki, przedmioty i kategorie zajęć. Przejrzysz je i poprawisz przed utworzeniem grupy.</span>')}${o('manual','<b>Od zera</b><span>Pusta grupa. Rangi, odznaki i przedmioty dodasz później, krok po kroku.</span>')}</div>${err('path')}</div>
 ${S.path==='quick'?`<div class="fsec"><h2 class="h3">Klimat zestawu</h2><p class="hint">Zmienia tylko nazwy rang i odznak. Zasady są wszędzie takie same.</p>
 <div class="opts" role="radiogroup" aria-label="Klimat">${Object.entries(PACKS).map(([k,p])=>`<button class="opt" role="radio" aria-checked="${S.pack===k}" data-act="pack" data-v="${k}"><b>${p.l}</b><span>${p.d}</span><em>${p.ranks.slice(0,3).join(' → ')} → …</em></button>`).join('')}</div></div>
 <div class="fsec"><h2 class="h3">Ile zajęć planujesz?</h2><p class="hint">Dopasujemy progi rang i ceny tak, żeby najwyższa ranga była osiągalna w semestrze.</p>
 <div class="nstep" role="group" aria-label="Liczba zajęć"><button data-act="num" data-k="classes" data-d="-1" aria-label="Mniej zajęć">${icon('minus')}</button><output aria-live="polite">${S.classes}</output><button data-act="num" data-k="classes" data-d="1" aria-label="Więcej zajęć">${icon('plus')}</button></div></div>`:''}`;}
function rrow(ic,x,val,extra=''){const ex=S.excl[x.id];return `<div class="rrow${ex?' x':''}">${icon(ic)}<span class="rn"><b>${esc(x.name)}</b>${extra}</span>${val}<button class="iconbtn" data-act="ex" data-id="${x.id}" aria-label="${ex?'Przywróć':'Usuń'}: ${esc(x.name)}" title="${ex?'Przywróć':'Usuń'}">${icon(ex?'undo':'x')}</button></div>`;}
const numIn=(x,pre,post)=>`<span class="rv2">${pre}<span class="inp sm"><input type="number" min="0" data-f="ov:${x.id}" value="${x.val}" aria-label="${esc(x.name)}: ${pre||'cena'}"></span>${post}</span>`;
function step3(){if(S.path==='manual')return `<div class="fsec"><h2 class="h3">Podsumowanie</h2><p class="hint">Grupa powstanie pusta. Po utworzeniu zobaczysz listę kroków do uzupełnienia.</p>
 <dl class="sumt"><dt>Nazwa</dt><dd>${esc(S.name)}</dd><dt>Waluta</dt><dd style="display:flex;align-items:center;gap:8px">${tok(24)}${esc(f1())}</dd><dt>Życia na start</dt><dd>${S.lives}</dd><dt>Ranking</dt><dd>${S.ranking?'Widoczny dla studentów':'Ukryty'}</dd></dl></div>`;
 const g=gen(),cnt=a=>a.filter(x=>!S.excl[x.id]).length,z=(t,a,rows)=>`<section class="rz"><h3 class="h3">${t} <span class="zone-n">${cnt(a)}</span></h3>${rows}</section>`;
 return `<div class="fsec"><h2 class="h3">Zestaw „${PACKS[S.pack].l}” dla ${S.classes} zajęć</h2><p class="hint">Usuń, czego nie potrzebujesz, i popraw liczby. Nazwy i opisy zmienisz po utworzeniu grupy.</p>
 <div class="rgrid">${z('Rangi',g.ranks,g.ranks.map((r,i)=>rrow('rank',r,i?numIn(r,'od',''):'<span class="rv2">od 0</span>',`<small>${r.disc?`−${r.disc}% w sklepie`:'Ranga startowa'}</small>`)).join(''))}
 ${z('Przedmioty w sklepie',g.items,g.items.map(x=>rrow('bag',x,numIn(x,'','<span class="tok" style="--s:20px"><span>'+curImg()+'</span></span>'))).join(''))}
 ${z('Odznaki',g.badges,g.badges.map(x=>rrow('badge',x,'',`<small>${x.rule}</small>`)).join(''))}
 ${z('Kategorie zajęć <small class="k">(szablon „Zajęcia”)</small>',g.cats,g.cats.map(x=>rrow('grid',x,`<span class="rv2">+${x.val}</span>`)).join(''))}</div></div>`;}
function preview(){if(S.step===0)return `<section class="panel pv"><h3>Karta na liście grup</h3><article class="card neutral gtile"><div class="card-f"><div class="card-i"><div class="art art-img" style="${artStyle()}"></div><div class="card-top"><h3 class="card-name${S.name?'':' ph'}">${esc(S.name||'Nazwa grupy')}</h3></div><p class="small">Prowadzi John Curtin</p></div></div></article></section>
 <section class="panel pv"><h3>Panel boczny grupy</h3><section class="deck"><div class="deck-f"><div class="deck-i"><span class="deck-art" style="${artStyle()}"></span><div class="deck-head"><h2 class="deck-name${S.name?'':' ph'}">${esc(S.name||'Nazwa grupy')}</h2><p class="deck-role">Prowadzisz tę grupę</p></div><nav class="nav"><span class="nl">${icon('overview')}<span>Przegląd</span></span><span class="nl">${icon('users')}<span>Studenci</span></span><span class="nl">${icon('bag')}<span>Przedmioty</span></span></nav></div></div></section><span class="hint">Tło stołu za formularzem pokazuje, jak grafika wygląda jako tło grupy.</span></section>`;
 const mini=t=>`<div class="app mini" data-theme="${t}"><span class="bal">${tok(32)}<span><b>19</b><small>do wydania</small></span></span><span class="purse-t">${tok(50)}<b>19</b></span><span class="dlg-t">15${tok(22)}</span><span class="cost"><b>15</b></span></div>`;
 return `<section class="panel pv"><h3>Tak zobaczą walutę studenci</h3><div class="cprev">${mini('light')}${mini('dark')}</div></section>
 <section class="panel pv"><h3>W zdaniach</h3><div class="say${S.cur.n1?'':' ph'}"><div><span>Cena</span><b>1 ${esc(f1())}</b></div><div><span>Nagroda</span><b>3 ${esc(f2())}</b></div><div><span>Stan konta</span><b>12 ${esc(f5())}</b></div></div></section>`;}
function success(){const g=gen(),n=k=>g[k].filter(x=>!S.excl[x.id]).length,q=S.path==='quick';
 const todo=q?['Zaproś studentów: pokaż im kod albo kod QR.','Po pierwszych zajęciach utwórz arkusz ocen i oceń studentów.','Zajrzyj do sklepu i dopasuj opisy przedmiotów do swojej opowieści.']
  :['Dodaj rangi, żeby studenci widzieli, do czego dążą.','Dodaj przedmioty do sklepu.','Dodaj odznaki za szczególne osiągnięcia.','Utwórz szablon arkusza ocen.','Zaproś studentów: pokaż im kod albo kod QR.'];
 return `<section class="panel okv"><div class="ok-ic">${icon('check')}</div><h1>Grupa „${esc(S.name)}” jest gotowa</h1>
 <p class="lead">${q?`Utworzono ${n('ranks')} ${pl(n('ranks'),'rangę','rangi','rang')}, ${n('badges')} ${pl(n('badges'),'odznakę','odznaki','odznak')}, ${n('items')} ${pl(n('items'),'przedmiot','przedmioty','przedmiotów')} i ${n('cats')} ${pl(n('cats'),'kategorię','kategorie','kategorii')} w szablonie arkusza.`:'Grupa jest pusta. Poniżej znajdziesz kolejne kroki.'}</p>
 <p class="expl" style="margin-top:22px">${icon('qr')}<span>Kod do dołączenia utworzysz w zakładce <b>Zaproszenia</b>, kiedy będziesz go potrzebować. Możesz mieć kilka kodów naraz, z limitem osób albo datą ważności.</span></p>
 <h2 class="h3" style="margin-top:28px">Co dalej</h2><ol class="todo-l">${todo.map(t=>`<li>${t}</li>`).join('')}</ol>
 <div class="rowb"><button class="btn" data-act="finish">Przejdź do grupy</button><button class="btn sec" data-act="nav" data-to="t/invites">${icon('qr')}Utwórz zaproszenie</button></div></section>`;}
function refresh(){const p=app.querySelector('.pcol');if(p)p.innerHTML=preview();const b=app.querySelector('.tbg');if(b&&S.art)b.setAttribute('style',artStyle());}
function validate(){S.err={};if(S.step===0&&!S.name.trim())S.err.name='Podaj nazwę grupy.';if(S.step===1&&!S.cur.n1.trim())S.err.n1='Podaj nazwę waluty przynajmniej w pierwszej formie.';if(S.step===2&&!S.path)S.err.path='Wybierz, jak chcesz zacząć.';return !Object.keys(S.err).length;}
const ACT={theme(){G.theme=G.theme==='dark'?'light':'dark';app.dataset.theme=G.theme;sync();},
 next(){if(!validate()){render(true);const f=app.querySelector('[aria-invalid="true"],.err');if(f&&f.focus)f.focus();return;}if(S.step===3){S.done=true;render();return;}S.step++;S.max=Math.max(S.max,S.step);render();},
 back(){S.err={};S.step--;render();},goto(a){const i=+a.dataset.i;if(i<=S.max){S.err={};S.step=i;render();}},
 art(a){S.art=a.dataset.v;S.focal=[50,50];render(true);},cicon(a){S.cur.icon=a.dataset.v;render(true);},
 coin(){S.cur.coin=!S.cur.coin;render(true);},ranking(){S.ranking=!S.ranking;render(true);},
 num(a){const k=a.dataset.k,lim=k==='lives'?[0,10]:[4,30];S[k]=Math.min(lim[1],Math.max(lim[0],S[k]+ +a.dataset.d));if(k==='classes')S.over={};render(true);},
 path(a){S.path=a.dataset.v;S.err={};render(true);},pack(a){S.pack=a.dataset.v;render(true);},
 ex(a){S.excl[a.dataset.id]=!S.excl[a.dataset.id];render(true);},
 focal(a,e){const r=a.getBoundingClientRect();S.focal=[Math.round((e.clientX-r.left)/r.width*100),Math.round((e.clientY-r.top)/r.height*100)];const k=app.querySelector('.mk');if(k){k.style.left=S.focal[0]+'%';k.style.top=S.focal[1]+'%';}refresh();},
 copy(){toast(icon('check')+'Skopiowano kod K7RB2Q');},hint(){hint('That screen isn’t part of this slice.');}};
ON('input',e=>{const t=e.target,f=t.dataset.f;if(!f)return;
 if(f.startsWith('ov:')){S.over[f.slice(3)]=Math.max(0,parseInt(t.value,10)||0);return;}
 if(/^n[125]$/.test(f))S.cur[f]=t.value;else S[f]=t.value;
 if(S.err[f]&&t.value.trim()){delete S.err[f];t.parentNode.classList.remove('bad');t.removeAttribute('aria-invalid');const m=app.querySelector('#e-'+f);if(m)m.remove();}refresh();});
ON('change',e=>{const t=e.target,k=t.dataset.file;if(!k||!t.files[0])return;const r=new FileReader();
 r.onload=()=>{if(k==='art'){S.upload=r.result;S.art='upload';S.focal=[50,50];render(true);}else{const im=new Image();im.onload=()=>{S.cur.upload=r.result;S.cur.icon='upload';S.cur.px=Math.max(im.naturalWidth,im.naturalHeight)<=256;render(true);};im.src=r.result;}};r.readAsDataURL(t.files[0]);});
DON('keydown',e=>{if(e.key==='Enter'&&e.target.matches&&e.target.matches('#f-name,#f-n1,#f-n2,#f-n5')){e.preventDefault();ACT.next();}});
const DEMO={name:'Zakon Algorytmów',story:'W Królestwie Danych każdy giermek zaczyna od prostych zadań. Tylko najwytrwalsi zdobędą tytuł kasztelana i klucz do biblioteki zakonu.',art:'castle',focal:[50,50],cur:{n1:'Złota Moneta',n2:'Złote Monety',n5:'Złotych Monet',icon:'coin',upload:null,coin:false,px:false},path:'quick',pack:'fantasy',max:3};

delete ACT.theme;
ACT.hint = () => hint('Not wired in this mockup.');
ACT.finish = () => { nav('t/home'); toast(icon('check') + `Grupa „${esc(S.name)}” jest gotowa. Zaproszenia znajdziesz w zakładce Zaproszenia.`); };
ACT.reset = () => { Object.assign(S, fresh()); render(false); };

reg('form', {
  act: ACT,
  setView() { Object.assign(S, fresh()); },
  bg() { return S.art ? `<div class="tbg" style="${artStyle()}"></div><div class="ttint"></div>` : null; },
  page() {
    const body = S.done ? success()
      : `<div class="wiz${S.step > 1 ? ' full' : ''}"><section class="panel fcol" aria-labelledby="st-h"><h2 class="sr" id="st-h">${STEPS()[S.step]}</h2>${[step0, step1, step2, step3][S.step]()}</section>${S.step < 2 ? `<aside class="pcol" aria-label="Podgląd">${preview()}</aside>` : ''}</div>
        <div class="panel wbar">${S.step ? `<button class="btn sec" data-act="back">${icon('chevLeft')}Wstecz</button>` : `<button class="btn sec" data-act="nav" data-to="t/groups">${icon('chevLeft')}Anuluj</button>`}<span class="sp"></span><span class="k">Krok ${S.step + 1} z 4</span><button class="btn" data-act="next">${S.step === 3 ? (S.path === 'quick' ? 'Utwórz grupę z zestawem' : 'Utwórz pustą grupę') : 'Dalej'}${S.step < 3 ? icon('chevRight') : ''}</button></div>`;
    return `<div class="page">${S.done ? '' : `<section class="panel phead" style="display:block"><p class="crumbs"><a href="#/t/groups" data-act="nav" data-to="t/groups">Grupy</a>${icon('chevRight')}<span>Nowa grupa</span></p><h1>Nowa grupa</h1><p class="lead">Zajmie to kilka minut. Wszystko zmienisz później w ustawieniach grupy.</p>${stepper()}</section>`}${body}</div>`;
  }
});
})();
