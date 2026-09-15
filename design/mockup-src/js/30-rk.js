/* ===== module: rk (ranking + supporting teachers, from t/rk.html) ===== */
(() => {
const ON = (t, f) => on('rk', t, f), DON = (t, f) => ondoc('rk', t, f);
const STU = DB.students;
const ME = DB.me().name;
/*BODY:rk*/

const ROUTES_OF = {rt: 't/ranking', rs: 's/ranking', teachers: 't/teachers'};
['bell', 'readN', 'readAll', 'theme'].forEach(k => delete ACT[k]);
ACT.close = function () { S.modal = null; closeLayer(); };

reg('rk', {
  act: ACT, layer,
  closeLayer() { S.modal = null; S.pop = false; },
  setView(v) { S.view = v; S.modal = null; S.pop = false; },
  page() { setRoute(ROUTES_OF[S.view]); return `<div class="page">${{rt: vRT, rs: vRS, teachers: vTeachers}[S.view]()}</div>`; }
});
})();
