/* ===== module: sp (student pages + states gallery, from t/sp.html) ===== */
(() => {
const ON = (t, f) => on('sp', t, f), DON = (t, f) => ondoc('sp', t, f);
const ME = DB.me();
/*BODY:sp*/

const ROUTES_OF = {items: 's/my-items', ranks: 's/ranks', badges: 's/badges', hist: 's/history', states: 's/states'};
delete ACT.hint;
ACT.go = a => nav(a.dataset.v && ROUTES_OF[a.dataset.v] ? ROUTES_OF[a.dataset.v] : a.dataset.to);

reg('sp', {
  act: ACT,
  setView(v) { if (v === 'loading') { S.view = 'items'; S.loading = true; setTimeout(() => { S.loading = false; if ((ROUTE[G.route] || {}).view === 'loading') { G.route = 's/my-items'; location.hash = '#/s/my-items'; } render(false); }, 1700); } else { S.view = v; S.loading = false; } },
  page() {
    if (!S.loading) setRoute(ROUTES_OF[S.view]);
    return `<div class="page">${S.loading ? vSkeleton() : VIEWS[S.view]()}</div>`;
  }
});
})();
