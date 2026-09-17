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

/*BODY:main*/

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
