/* ===== module: student (teacher's view of one student, from t/student.html) ===== */
(() => {
const ON = (t, f) => on('student', t, f), DON = (t, f) => ondoc('student', t, f);
/*BODY:student*/

delete ACT.theme;
ACT.hint = () => hint('Not wired in this mockup.');

reg('student', {
  act: ACT, layer,
  closeLayer() { S.modal = null; },
  setView(v, o) {
    if (o && o.i != null) DB.selIdx = o.i;
    S.filter = 'all'; S.fresh = null;
    const tab = o && o.tab;
    S.tab = (tab === 'hist') ? 'hist' : (tab === 'assign' || tab === 'adjust') ? 'badges' : 'badges';
    S.modal = tab === 'assign' ? {m: 'assign', q: '', sel: null} : tab === 'adjust' ? {m: 'adjust', sign: 1, amt: '', why: ''} : null;
  },
  page() { return `<div class="page">${sheet()}${tabs()}<section class="panel tp" id="tp" role="tabpanel" aria-labelledby="tab-${S.tab}">${{badges: tBadges, items: tItems, hist: tHist}[S.tab]()}</section></div>`; }
});
})();
