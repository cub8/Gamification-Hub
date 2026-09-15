/* ===== module: ag (grading sheets + templates, from t/ag.html) ===== */
(() => {
const ON = (t, f) => on('ag', t, f), DON = (t, f) => ondoc('ag', t, f);
/*BODY:ag*/

const ROUTES_OF = {list: 't/sheets', newtpl: 't/sheet-template-new', edittpl: 't/sheet-template-edit', group: 't/sheet-settings'};
delete ACT.theme;
ACT.go = a => { const v = a.dataset.v; if (!v) return nav(a.dataset.to); if (v === 'list') return nav('t/sheets'); open(v, a.dataset.t); render(false); };
ACT.hint = () => hint('Not wired in this mockup.');
ACT.grade = () => nav('t/grade');

reg('ag', {
  act: ACT, layer,
  closeLayer() { S.modal = null; S.dlg = null; },
  setView(v, o) { open(v, (o && o.t) || (S.tpls[0] || {}).id); },
  page() {
    const v = S.view;
    setRoute(ROUTES_OF[v]);
    if (v === 'list') return `<div class="page">${viewList()}</div>`;
    const T = {newtpl: ['Nowy szablon arkusza', 'Nowy szablon'], edittpl: ['Edytuj szablon arkusza', S.orig && JSON.parse(S.orig).name], group: ['Ustawienia arkusza', 'Laboratoria 5']}[v];
    return `<div class="page"><section class="panel phead" style="display:block"><p class="crumbs"><a href="#/t/sheets" data-act="go" data-v="list">Arkusze ocen</a>${icon('chevRight')}<span>${esc(T[1])}</span></p><h1>${T[0]}</h1><p class="lead">${v === 'group' ? 'Zmiany dotyczą tylko tego arkusza.' : 'Podgląd obok pokazuje nagłówek tabeli ocen.'}</p></section>
      <div class="wiz"><section class="panel fcol">${editor()}</section><aside class="pcol" aria-label="Podgląd">${gridPrev()}</aside></div>
      <div style="margin-bottom:14px"><div class="panel wbar"><button class="linkbtn" data-act="cancel">Anuluj</button><span class="sp"></span>${v === 'newtpl' ? `<button class="btn" data-act="save">${icon('plus')}Utwórz szablon</button>` : `<span class="k" id="dk">${dirty() ? 'Niezapisane zmiany' : 'Brak zmian'}</span><button class="btn" id="sv" data-act="save"${dirty() ? '' : ' disabled'}>Zapisz zmiany</button>`}</div></div></div>`;
  }
});
})();
