/* ===== module: br (badge + rank forms, from t/br.html) ===== */
(() => {
const ON = (t, f) => on('br', t, f), DON = (t, f) => ondoc('br', t, f);
/*BODY:br*/

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
