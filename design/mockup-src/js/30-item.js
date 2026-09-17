/* ===== module: item (item create/edit form, from t/item.html) ===== */
(() => {
const ON = (t, f) => on('item', t, f), DON = (t, f) => ondoc('item', t, f);
/*BODY:item*/

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
