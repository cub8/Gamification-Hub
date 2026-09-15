/* ===== module: main (shop, group overview, dashboard, grading — from ct/app.js) ===== */
(() => {
const ON = (t, f) => on('main', t, f), DON = (t, f) => ondoc('main', t, f);

const S = {
  view: 'shop', filter: 'all', search: '',
  get student() { return DB.me(); },
  get ledger() { return DB.me().hist; },
  get purch() { return DB.purch; },
  get grid() { return DB.grid; }
};
const STU = DB.students.map(s => s.name);

/* module-scoped overlay (buy dialog, mobile sheet, award review) */
let LK = null, LD = {};
function layerHtml() {
  return LK === 'buy' ? ovl(dlgBuy(LD.id)) : LK === 'sheet' ? ovl(dlgSheet(LD.id)) : LK === 'review' ? ovl(dlgReview()) : '';
}
function layerRender() {
  const L = app.querySelector('#layer'); if (!L) return;
  if (!LK) { L.innerHTML = ''; L.classList.remove('on'); return; }
  L.innerHTML = layerHtml(); L.classList.add('on');
  const f = L.querySelector('[data-focus]'); if (f) f.focus({preventScroll: true});
}
function openLayer(k, d) { LK = k; LD = d || {}; layerRender(); }
function closeLayer() { LK = null; layerRender(); }

/* ---------------- Cards ---------------- */
function itemCard(x, o = {}) {
  const {it, state, reasons, pct, price, missing} = x, st = S.student;
  const tags = [];
  if (pct) tags.push(`<span class="tag tag-disc" title="${esc(discNames(it).join(', '))}">−${pct}% za odznaki</span>`);
  if (it.zeroLives) tags.push(`<span class="tag tag-life">${icon('heart')}Działa przy 0 życiach</span>`);
  let foot, mfoot;
  if (state === 'afford') {
    foot = `<button class="btn" data-act="buy" data-id="${it.id}">Kup za ${price}</button>`;
    mfoot = `<span class="ms ok">Kup za ${price}</span>`;
  } else if (state === 'save') {
    foot = `<div class="need"><div class="need-t">Zbierz jeszcze <b>${missing}</b>${coin()}</div>${bar(st.balance, price, 'Postęp zbierania')}</div>`;
    mfoot = `<span class="ms">Jeszcze ${missing} ${coin()}</span>`;
  } else {
    const rr = reasons.find(r => r.t === 'rank');
    foot = `<div class="req">${reasons.map(reqText).join('<br>')}${rr ? bar(st.total, rr.r.min, 'Postęp do rangi') : ''}</div>`;
    mfoot = `<span class="ms">${icon('lock')}${reasons[0].t === 'rank' ? 'Wymaga rangi' : 'Wymaga odznaki'}</span>`;
  }
  return `<article class="card item ${state}${o.full ? ' full' : ''}"${o.full ? '' : ` data-act="open" data-id="${it.id}"`}>
  <div class="card-f"><div class="card-i">
    <div class="card-top"><h3 class="card-name">${esc(it.name)}</h3>${costChip(price, pct ? it.cost : null)}</div>
    <div class="art">${glyph(it.glyph)}${state === 'sealed' ? `<span class="seal">${icon('lock')}<span>${esc(sealLabel(reasons[0]))}</span></span>` : ''}</div>
    ${tags.length ? `<div class="tags">${tags.join('')}</div>` : ''}
    <p class="rules">${esc(it.rules)}</p>
    <p class="flavor">${esc(it.flavor)}</p>
    ${o.nofoot ? '' : `<div class="card-foot">${foot}</div><div class="card-mfoot">${mfoot}</div>`}
  </div></div></article>`;
}
function badgeCard(b, earned) {
  return `<article class="card badge flip${earned ? '' : ' down'}" data-badge="${b.id}" aria-label="Odznaka ${esc(b.name)}${earned ? '' : ', jeszcze niezdobyta'}">
  <div class="flip-in">
    <div class="face front"><div class="card-f"><div class="card-i">
      <div class="card-top"><h3 class="card-name">${esc(b.name)}</h3></div>
      <div class="art">${glyph(b.glyph)}</div>
      <p class="rules">${esc(b.rule)}</p>
      <p class="flavor">${esc(b.flavor)}</p>
      <div class="card-foot"><span class="tag tag-disc">−${b.disc}% w sklepie</span></div>
    </div></div></div>
    <div class="face back" aria-hidden="${earned}"><div class="card-f"><div class="card-i back-i">
      <div class="back-art">${MARK}</div>
      <h3 class="card-name">${esc(b.name)}</h3>
      <p class="how"><span>Jak zdobyć</span>${esc(b.rule)}</p>
    </div></div></div>
  </div></article>`;
}
function handCard(o, i, n) {
  const it = ITEM[o.id], rot = ((i - (n - 1) / 2) * 6).toFixed(1);
  return `<article class="card item hc full" style="--rot:${rot}deg"><div class="card-f"><div class="card-i">
    <div class="card-top"><h3 class="card-name">${esc(it.name)}</h3></div>
    <div class="art">${glyph(it.glyph)}</div>
    <p class="rules">${esc(it.rules)}</p>
    <div class="card-foot"><span class="small">Kupione: ${esc(o.when)}</span></div>
  </div></div></article>`;
}
/* ---------------- Views ---------------- */
function zone(title, xs, cls = '') {
  if (!xs.length) return '';
  return `<section class="zone ${cls}"><h2 class="zone-l"><span>${title}</span><span class="zone-n">${xs.length}</span></h2><div class="cards">${xs.map(x => itemCard(x)).join('')}</div></section>`;
}
function viewShop() {
  const st = S.student, xs = shopItems().map(it => ({it, ...itemState(it)}));
  const by = s => xs.filter(x => x.state === s);
  const disc = st.badges.map(id => BADGE[id]).filter(b => b.disc);
  return `<div class="page">
    <section class="panel phead">
      <div class="phead-t"><h1>Sklep</h1><p class="lead">Masz ${st.balance} ${curA(st.balance)} do wydania.${disc.length ? ` ${disc.length > 1 ? 'Twoje odznaki' : 'Twoja odznaka'} ${andList(disc.map(b => esc(b.name)))} ${disc.length > 1 ? 'obniżają' : 'obniża'} ceny niektórych przedmiotów.` : ''}</p></div>
      <div class="purse-mini">${coin('carrot', 'coin-md')}<div><b>${st.balance}</b><small>do wydania</small></div><span class="div"></span><div><b>${st.total}</b><small>zebrane łącznie</small></div></div>
    </section>
    ${zone('Stać cię teraz', by('afford'))}${zone('Zbierasz na to', by('save'))}${zone('Zapieczętowane', by('sealed'))}
  </div>`;
}
function viewHome() {
  const st = S.student, ri = rankIdx(st.total), r = RANKS[ri], nx = RANKS[ri + 1], g = GROUP.kk;
  const earned = BADGES.filter(b => st.badges.includes(b.id)).length;
  const afford = shopItems().filter(it => itemState(it).state === 'afford').length;
  return `<div class="page home">
    <section class="card neutral lore"><div class="card-f"><div class="card-i">
      <div class="art art-img" style="background-image:${ART[g.art]}" role="img" aria-label="Grafika grupy"></div>
      <div class="lore-b"><h1>${esc(g.name)}</h1><p class="lore-t">${esc(g.lore)}</p><p class="lore-a">Prowadzi ${esc(g.owner)}</p></div>
    </div></div></section>
    <section class="card gold purse" aria-label="Twoje ${CUR.carrot.nom2}"><div class="card-f"><div class="card-i">
      <p class="k">Do wydania</p>
      <div class="big">${coin('carrot', 'coin-lg')}<span class="num">${st.balance}</span></div>
      <p class="unit">${curN(st.balance)}</p>
      <dl class="stats"><div><dt>Zebrane łącznie</dt><dd>${st.total}</dd></div><div><dt>Życia</dt><dd class="hearts" aria-label="${st.lives} z 3">${hearts(st.lives, 3)}</dd></div></dl>
      <button class="btn" data-act="nav" data-to="s/shop">${icon('bag')}Otwórz sklep</button>
    </div></div></section>
    <section class="card gold rankc"><div class="card-f"><div class="card-i">
      <div class="rk-top"><p class="k">Twoja ranga</p><h2 class="rank-name">${esc(r.name)}</h2></div>
      <div class="art">${glyph(r.glyph)}</div>
      ${nx ? `<div class="rank-p"><div class="rank-pt"><span class="tnum">${st.total} z ${nx.min}</span><span>${esc(nx.name)}</span></div>${bar(st.total - r.min, nx.min - r.min, 'Postęp do następnej rangi')}<p class="small">Jeszcze <b>${nx.min - st.total}</b> do rangi ${esc(nx.name)}. Ta ranga daje −${nx.disc}% w sklepie.</p></div>` : ''}
      <p class="small rk">${icon('podium')}2. miejsce w rankingu grupy</p>
    </div></div></section>
    <section class="zone z-badges"><h2 class="zone-l"><span>Odznaki</span><span class="zone-n" data-bcount>${earned} z ${BADGES.length}</span></h2><div class="cards cards-b">${BADGES.map(b => badgeCard(b, st.badges.includes(b.id))).join('')}</div></section>
    <section class="zone z-hand"><h2 class="zone-l"><span>Twoje przedmioty</span><span class="zone-n">${st.items.length}</span></h2>
      <div class="hand">${st.items.map((o, i) => handCard(o, i, st.items.length)).join('')}
        <div class="panel slot-e"><p>Dobierz coś w sklepie. Stać cię teraz na ${afford} ${pl(afford, 'przedmiot', 'przedmioty', 'przedmiotów')}.</p><button class="btn sec" data-act="nav" data-to="s/shop">Przejdź do sklepu</button></div>
      </div></section>
    <section class="panel ledger"><h2 class="h2">Ostatnie zmiany</h2>
      <ul class="led">${S.ledger.slice(0, 6).map(l => `<li class="led-r"><span class="led-m ${l.type} oct" style="--c:3px" aria-hidden="true"></span><span class="led-t">${esc(l.t)}<small>${{earn:'Nagroda',spend:'Zakup',corr:'Korekta'}[l.type]}, ${esc(l.when)}</small></span><span class="led-a ${l.type}">${l.amt > 0 ? '+' : '−'}${Math.abs(l.amt)}</span></li>`).join('')}</ul>
      <button class="linkbtn" data-act="nav" data-to="s/history">Pokaż całą historię</button>
    </section>
  </div>`;
}
function viewDash() {
  const recent = S.purch.filter(p => p.day !== 'Wcześniej'), gset = new Set(recent.map(p => p.g));
  const list = S.filter === 'all' ? S.purch : S.purch.filter(p => p.g === S.filter);
  const gIds = [...new Set(S.purch.map(p => p.g))];
  const prow = p => { const g = GROUP[p.g], it = pItem(p); return `<li class="prow${p.fresh ? ' fresh' : ''}">${miniCard(it.glyph)}<span class="p-main"><b>${esc(it.name)}</b><span>${esc(p.stu)}</span><span class="p-gm">${gchip(g)}</span></span><span class="p-g">${gchip(g)}</span>${costChip(p.price, null, g.cur, 'sm')}<span class="p-time">${p.time}</span></li>`; };
  const newIn = id => recent.filter(p => p.g === id).length;
  return `<div class="page">
    <section class="panel phead"><div class="phead-t"><h1>Dzień dobry, John</h1><p class="lead">Od wczoraj studenci kupili ${recent.length} ${pl(recent.length, 'przedmiot', 'przedmioty', 'przedmiotów')} w ${gset.size} ${pl(gset.size, 'grupie', 'grupach', 'grupach')}.</p></div></section>
    <div class="dash">
      <section class="panel purch" aria-labelledby="pt"><h2 class="h2" id="pt">Ostatnie zakupy</h2>
        <div class="filters" role="group" aria-label="Pokaż zakupy z grupy"><button class="fchip" data-act="filter" data-g="all" aria-pressed="${S.filter === 'all'}">Wszystkie grupy</button>${gIds.map(id => `<button class="fchip" data-act="filter" data-g="${id}" aria-pressed="${S.filter === id}">${gthumb(GROUP[id])}${esc(GROUP[id].name)}</button>`).join('')}</div>
        ${['Dziś', 'Wczoraj', 'Wcześniej'].map(d => { const rows = list.filter(p => p.day === d); return rows.length ? `<h3 class="day">${d}</h3><ul class="plist">${rows.map(prow).join('')}</ul>` : ''; }).join('')}
      </section>
      <div class="dash-side">
        <section class="card todo"><div class="card-f"><div class="card-i">
          <p class="k">Czeka na ocenę</p><h2 class="todo-t">Laboratoria 5</h2>${gchip(GROUP.kk)}
          <p class="small">Obecność i punktualność są już przyznane. Zostało 9 kategorii dla 12 studentów.</p>
          <button class="btn" data-act="nav" data-to="t/grade">Oceń</button>
        </div></div></section>
        <section class="panel mygroups"><h2 class="h2">Twoje grupy</h2>
          <ul class="gtl">${GROUPS.map(g => { const n = newIn(g.id); return `<li><a href="#" class="gt" data-act="${g.id === 'kk' ? 'nav' : 'stub'}" data-to="t/home" data-g="${g.id}">${gthumb(g, 'lg')}<span><b>${esc(g.name)}</b><small>${g.role === 'owner' ? 'Prowadzisz' : 'Wspierasz'}, ${g.students} ${pl(g.students, 'student', 'studentów', 'studentów')}</small></span>${n ? `<span class="gt-new">${n} ${pl(n, 'nowy zakup', 'nowe zakupy', 'nowych zakupów')}</span>` : ''}</a></li>`; }).join('')}</ul>
          <button class="btn sec" data-act="nav" data-to="t/new-group">${icon('plus')}Utwórz grupę</button>
        </section>
      </div>
    </div>
  </div>`;
}
const CS = ['empty', 'pending', 'awarded'], CL = ['puste', 'zaznaczone', 'przyznane'];
const cellInner = v => v === 0 ? '' : v === 1 ? icon('check') : icon('check') + icon('lock', 'lk');
const cellBtn = (i, j) => { const v = S.grid[i][j]; return `<button class="cell ${CS[v]}" data-act="cell" data-i="${i}" data-j="${j}" aria-pressed="${v === 1}" aria-label="${esc(STU[i])}, ${esc(CATS[j].name)}: ${CL[v]}"${v === 2 ? ' title="Przyznane, nie można cofnąć"' : ''}>${cellInner(v)}</button>`; };
function sumHtml(i) { let a = 0, p = 0; CATS.forEach((c, j) => { const v = S.grid[i][j]; if (v === 2) a += c.prize; if (v === 1) p += c.prize; }); return `<span class="s-a">${a}</span>${p ? `<span class="s-p">+${p}</span>` : ''}`; }
function pendingStats() { let n = 0, sum = 0; const stu = new Set(); S.grid.forEach((r, i) => r.forEach((v, j) => { if (v === 1) { n++; sum += CATS[j].prize; stu.add(i); } })); return {n, sum, stu:stu.size}; }
function abarInner() {
  const {n, sum, stu} = pendingStats();
  if (!n) return `<p class="abar-t">Nic nie jest zaznaczone. Kliknij pola studentów, którzy zdobyli nagrody.</p><div class="abar-b"><button class="btn" disabled>Przejrzyj i przyznaj</button></div>`;
  return `<p class="abar-t"><b>Zaznaczone teraz: ${n} ${pl(n, 'pole', 'pola', 'pól')}</b> u ${stu} ${pl(stu, 'studenta', 'studentów', 'studentów')}, razem ${costChip('+' + sum, null, 'carrot', 'sm')}</p><div class="abar-b"><button class="btn sec" data-act="clear">Wyczyść zaznaczenia</button><button class="btn" data-act="review">Przejrzyj i przyznaj</button></div>`;
}
function viewGrade() {
  const q = S.search.trim().toLowerCase();
  return `<div class="gradeview">
    <section class="panel phead ghead">
      <div class="phead-t"><p class="crumbs"><a href="#/t/sheets" data-act="nav" data-to="t/sheets">Arkusze ocen</a>${icon('chevRight')}<a href="#/t/sheets" data-act="nav" data-to="t/sheets">Laboratoria</a></p><h1>Laboratoria 5</h1>
        <p class="lead">11 kategorii, 12 studentów. Zaznacz, kto zdobył nagrody, a przed przyznaniem przejrzysz wszystko jeszcze raz.</p></div>
      <div class="ghead-r">
        <label class="search">${icon('search')}<input type="search" placeholder="Szukaj studenta" data-inp="search" value="${esc(S.search)}" aria-label="Szukaj studenta"></label>
        <ul class="legend" aria-label="Legenda"><li><span class="cell sm empty"></span>Puste</li><li><span class="cell sm pending">${icon('check')}</span>Zaznaczone teraz</li><li><span class="cell sm awarded">${icon('check')}</span>Przyznane, nie do cofnięcia</li></ul>
      </div>
    </section>
    <section class="panel board"><div class="board-scroll"><table class="grid">
      <thead><tr><th class="th-stu" scope="col">Student</th>${CATS.map((c, j) => `<th scope="col"><div class="thc"><span class="thn" title="${esc(c.flavor)}">${esc(c.name)}</span>${costChip('+' + c.prize, null, 'carrot', 'sm')}<button class="colbtn" data-act="col" data-j="${j}" title="Zaznacz całą kolumnę">${icon('checks')}Wszyscy</button></div></th>`).join('')}<th class="th-sum" scope="col">Razem</th></tr></thead>
      <tbody>${STU.map((s, i) => `<tr data-i="${i}"${q && !s.toLowerCase().includes(q) ? ' hidden' : ''}><th scope="row" class="td-stu"><span>${avatar(s, 'sm')}${esc(s)}</span></th>${CATS.map((_, j) => `<td>${cellBtn(i, j)}</td>`).join('')}<td class="td-sum" data-sum="${i}">${sumHtml(i)}</td></tr>`).join('')}</tbody>
    </table></div></section>
    <section class="panel abar" aria-live="polite">${abarInner()}</section>
  </div>
  <div class="grade-mobile"><section class="panel gm">
    <div class="gm-ic oct">${icon('desktop')}</div>
    <h1 class="h2">Laboratoria 5</h1>
    <p class="lead">Ocenianie w tabeli działa na komputerze. Ta tabela ma 11 kategorii i 12 studentów, więc na telefonie byłaby nieczytelna.</p>
    <p class="small">Na telefonie sprawdzisz ostatnie zakupy i powiadomienia.</p>
    <button class="btn sec" data-act="nav" data-to="t/dash">Wróć na start</button>
  </section></div>`;
}
const VIEWS = {shop:viewShop, home:viewHome, dash:viewDash, grade:viewGrade};

/* ---------------- Overlays ---------------- */
const ovl = (inner, cls = '') => `<div class="ovl ${cls}" data-act="close">${inner}</div>`;
const pop = (inner, cls = '') => `<div class="pop-ovl" data-act="close"><div class="pop-w ${cls}" data-act="noop"><div class="pop">${inner}</div></div></div>`;
const dlg = (inner, label, cls = '') => `<div class="dlg ${cls}" role="dialog" aria-modal="true" aria-labelledby="${label}" data-act="noop"><div class="dlg-in"><span class="grab" aria-hidden="true"></span>${inner}</div></div>`;
function dlgBuy(id) {
  const it = ITEM[id], x = itemState(it), after = S.student.balance - x.price;
  return dlg(`<h2 class="h2" id="bt">Kupić „${esc(it.name)}”?</h2>
    <div class="buy">${miniCard(it.glyph, 'lg')}<dl class="buy-dl"><dt>Cena</dt><dd>${x.pct ? `<s>${it.cost}</s>` : ''}${x.price}${coin()}</dd><dt>Zostanie Ci</dt><dd>${after}${coin()}</dd></dl></div>
    ${x.pct ? `<p class="small note">Zniżka −${x.pct}% dzięki odznakom: ${esc(andList(discNames(it)))}.</p>` : ''}
    <p class="small note">${icon('bell')}Prowadzący dostanie powiadomienie o zakupie.</p>
    <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="confirm-buy" data-id="${id}" data-focus>Kup za ${x.price}</button></div>`, 'bt');
}
function dlgSheet(id) {
  const it = ITEM[id], x = {it, ...itemState(it)};
  const act = x.state === 'afford' ? `<button class="btn" data-act="buy" data-id="${id}" data-focus>Kup za ${x.price}</button>`
    : x.state === 'save' ? `<p class="small">Zbierz jeszcze <b>${x.missing}</b>, żeby to kupić.</p>`
    : `<p class="small">${x.reasons.map(reqText).join(' ')}</p>`;
  return dlg(`<span class="sr" id="st">${esc(it.name)}</span>${itemCard(x, {full:true, nofoot:true})}<div class="dlg-b">${act}<button class="btn sec" data-act="close">Zamknij</button></div>`, 'st', 'dlg-sheet');
}
function dlgReview() {
  const rows = STU.map((s, i) => ({s, cats:CATS.filter((c, j) => S.grid[i][j] === 1)})).filter(r => r.cats.length);
  const {sum} = pendingStats(), n = rows.length;
  return dlg(`<h2 class="h2" id="rv">Przyznajesz ${sum} ${curA(sum)} ${n} ${pl(n, 'studentowi', 'studentom', 'studentom')}</h2>
    <p class="warn">${icon('lock')}Po zatwierdzeniu nie da się tego cofnąć. Sprawdź listę, zanim przyznasz nagrody.</p>
    <ul class="rv">${rows.map(r => `<li><span class="rv-n">${avatar(r.s, 'sm')}${esc(r.s)}</span><span class="rv-c">${r.cats.map(c => `<span class="rvchip oct" style="--c:4px">${esc(c.name)}<b>+${c.prize}</b></span>`).join('')}</span><span class="rv-s">+${r.cats.reduce((a, c) => a + c.prize, 0)}</span></li>`).join('')}</ul>
    <div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Wróć do edycji</button><button class="btn gold" data-act="award">Przyznaj ${sum} ${curA(sum)}</button></div>`, 'rv', 'dlg-review');
}
function doBuy(id) {
  const it = ITEM[id], x = itemState(it); if (x.state !== 'afford') return;
  const st = S.student; if (!DB.buy(id)) return;
  closeLayer(); render(true);
  toast(`${icon('check')}Kupione: ${esc(it.name)}. Zostało Ci ${st.balance}.`);
}
function paintCell(i, j, extra = '') {
  const b = app.querySelector(`.cell[data-i="${i}"][data-j="${j}"]`); if (!b) return;
  const v = S.grid[i][j];
  b.className = `cell ${CS[v]}${extra}`; b.setAttribute('aria-pressed', v === 1);
  b.setAttribute('aria-label', `${STU[i]}, ${CATS[j].name}: ${CL[v]}`);
  if (v === 2) b.title = 'Przyznane, nie można cofnąć'; else b.removeAttribute('title');
  b.innerHTML = cellInner(v);
}
const paintSum = i => { const c = app.querySelector(`[data-sum="${i}"]`); if (c) c.innerHTML = sumHtml(i); };
const paintAbar = () => { const a = app.querySelector('.abar'); if (a) a.innerHTML = abarInner(); };
function repaintGrid() { STU.forEach((_, i) => { CATS.forEach((_, j) => paintCell(i, j)); paintSum(i); }); paintAbar(); }
const visibleRows = () => { const q = S.search.trim().toLowerCase(); return STU.map((_, i) => i).filter(i => !q || STU[i].toLowerCase().includes(q)); };
function doAward() {
  const {sum, stu} = pendingStats(), cells = [];
  S.grid.forEach((r, i) => r.forEach((v, j) => { if (v === 1) { r[j] = 2; cells.push([i, j]); } }));
  closeLayer();
  cells.forEach(([i, j], k) => { paintCell(i, j, ' stamp'); const b = app.querySelector(`.cell[data-i="${i}"][data-j="${j}"]`); if (b) b.style.setProperty('--d', `${k * 24}ms`); });
  STU.forEach((_, i) => paintSum(i)); paintAbar();
  toast(`${icon('check')}Przyznano ${sum} ${curA(sum)} ${stu} ${pl(stu, 'studentowi', 'studentom', 'studentom')}.`);
}
function badgeDemo() {
  if (S.view !== 'home') return;
  const st = S.student, had = st.badges.includes('mech');
  st.badges = had ? st.badges.filter(b => b !== 'mech') : [...st.badges, 'mech'];
  const el = app.querySelector('[data-badge="mech"]');
  if (el) { el.classList.toggle('down', had); el.classList.toggle('just', !had); if (!had) el.scrollIntoView({block:'nearest', behavior:'smooth'}); }
  const c = app.querySelector('[data-bcount]'); if (c) c.textContent = `${st.badges.length} z ${BADGES.length}`;
  if (!had) setTimeout(() => toast(`${icon('badge')}Nowa odznaka: Mechanik Załogi. Przyznał ją John Curtin.`), 500);
  syncToolbar();
}
const ACT = {
  noop() {}, close: closeLayer,
  nav(a) { const to = a.dataset.to; if (to && VIEWS[to]) { if (to !== S.view || S.layer) go(to); } else hint('That screen isn’t part of this first slice.'); },
  hint() { hint('That screen isn’t part of this first slice.'); },
  theme() { setTheme(G.theme === 'dark' ? 'light' : 'dark'); },
  join() { openLayer('join'); }, 'join-go'() { openLayer('joined'); },
  buy(a) { openLayer('buy', {id:a.dataset.id}); },
  open(a) { if (isMobile()) openLayer('sheet', {id:a.dataset.id}); },
  'confirm-buy'(a) { doBuy(a.dataset.id); },
  bal() { if (S.view !== 'home') go('home'); },
  bell() { S.notif = 0; const c = app.querySelector('.hd .count'); if (c) c.remove(); openLayer('notif'); },
  avatar() { openLayer('avatar'); }, switch() { openLayer('switch'); },
  collapse() { S.collapsed = !S.collapsed; render(true); },
  filter(a) { S.filter = a.dataset.g; render(true); },
  cell(a) { const i = +a.dataset.i, j = +a.dataset.j, v = S.grid[i][j]; if (v === 2) { toast(`${icon('lock')}To pole jest już przyznane i nie można go cofnąć.`); return; } S.grid[i][j] = v ? 0 : 1; paintCell(i, j); paintSum(i); paintAbar(); },
  col(a) { const j = +a.dataset.j, vis = visibleRows(), anyEmpty = vis.some(i => S.grid[i][j] === 0); vis.forEach(i => { if (S.grid[i][j] !== 2) S.grid[i][j] = anyEmpty ? 1 : 0; }); repaintGrid(); },
  clear() { S.grid.forEach(r => r.forEach((v, j) => { if (v === 1) r[j] = 0; })); repaintGrid(); },
  review() { openLayer('review'); }, award: doAward
};
function checkJoin() { const ins = [...app.querySelectorAll('[data-slot]')], b = app.querySelector('[data-join]'); if (b) b.disabled = !ins.every(i => i.value); }
ON('input', e => {
  const t = e.target;
  if (t.dataset.inp === 'search') { S.search = t.value; const q = t.value.trim().toLowerCase(); app.querySelectorAll('.grid tbody tr').forEach(tr => { tr.hidden = !!q && !STU[+tr.dataset.i].toLowerCase().includes(q); }); }
  if (t.dataset.slot != null) { t.value = t.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(-1); if (t.value) { const n = app.querySelector(`[data-slot="${+t.dataset.slot + 1}"]`); if (n) n.focus(); } checkJoin(); }
});
ON('keydown', e => {
  const t = e.target; if (!t.dataset || t.dataset.slot == null) return;
  if (e.key === 'Backspace' && !t.value) { const p = app.querySelector(`[data-slot="${+t.dataset.slot - 1}"]`); if (p) { p.value = ''; p.focus(); e.preventDefault(); checkJoin(); } }
  if (e.key === 'Enter') { const b = app.querySelector('[data-join]'); if (b && !b.disabled) b.click(); }
});
ON('paste', e => {
  const t = e.target; if (!t.dataset || t.dataset.slot == null) return;
  e.preventDefault();
  const txt = ((e.clipboardData || window.clipboardData).getData('text') || '').toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 6);
  const ins = [...app.querySelectorAll('[data-slot]')]; [...txt].forEach((c, k) => { if (ins[k]) ins[k].value = c; });
  ins[Math.min(txt.length, 5)].focus(); checkJoin();
});
DON('keydown', e => { if (e.key === 'Escape' && S.layer) closeLayer(); });

['nav', 'hint', 'theme', 'join', 'join-go', 'bal', 'bell', 'avatar', 'switch', 'collapse', 'noop'].forEach(k => delete ACT[k]);
ACT.close = closeLayer;
ACT.sheetSettings = () => nav('t/sheet-settings');

reg('main', {
  act: ACT, layer: layerRender, closeLayer,
  setView(v) { S.view = v; S.search = ''; LK = null; },
  page() {
    if (S.view === 'grade') return viewGrade();
    return VIEWS[S.view]();
  }
});
})();
