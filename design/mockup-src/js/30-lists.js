/* ===== module: lists (teacher lists + join-code modal, from t/lists.html) ===== */
(() => {
const ON = (t, f) => on('lists', t, f), DON = (t, f) => ondoc('lists', t, f);
const STUD = DB.students;
const NOWD = new Date('2026-09-11T12:00');
const invActive = v => (!v.max || v.uses < v.max) && (!v.exp || new Date(v.exp) > NOWD);
const activeInv = () => DB.invites.filter(invActive);
const dmy = iso => iso ? iso.slice(8, 10) + '.' + iso.slice(5, 7) + ', ' + iso.slice(11, 16) : null;
/*BODY:lists*/

const ROUTES_OF = {ranks: 't/ranks', badges: 't/badges', items: 't/items', students: 't/students'};
ACT.go = a => nav(ROUTES_OF[a.dataset.v] || a.dataset.to);
ACT.student = a => nav('t/student', {i: +a.dataset.i, tab: a.dataset.tab});
delete ACT.theme;

reg('lists', {
  act: ACT, layer,
  closeLayer() { S.modal = false; },
  setView(v) { S.view = v; S.q = ''; S.modal = false; },
  page() { setRoute(ROUTES_OF[S.view]); return `<div class="page">${VIEWS[S.view]()}</div>`; }
});
})();
