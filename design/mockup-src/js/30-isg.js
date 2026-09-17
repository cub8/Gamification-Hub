/* ===== module: isg (invites, group settings, student start, from t/isg.html) ===== */
(() => {
const ON = (t, f) => on('isg', t, f), DON = (t, f) => ondoc('isg', t, f);
const MY = DB.myGroups;
/*BODY:isg*/

const ROUTES_OF = {inv: 't/invites', set: 't/group-settings', start: 's/start'};
delete ACT.theme;
ACT.go = a => nav(ROUTES_OF[a.dataset.v] || a.dataset.to);
ACT.openGroup = a => (a.dataset.g === 'kk' ? nav(a.dataset.to || 's/home') : CORE_ACT.stub(a));

reg('isg', {
  act: ACT, layer,
  closeLayer() { S.modal = null; },
  setView(v) { S.view = v; S.modal = null; S.err = {}; },
  page() {
    setRoute(ROUTES_OF[S.view]);
    if (S.view === 'set' && !S.f) { S.f = {...F0}; S.orig = JSON.stringify(S.f); }
    return `<div class="page">${{inv: vInv, set: vSet, start: vStart}[S.view]()}</div>`;
  }
});
})();
