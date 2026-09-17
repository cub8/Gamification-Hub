/* ===== module: gh (group index, teacher group home, student group settings) ===== */
(() => {
const ON = (t, f) => on('gh', t, f), DON = (t, f) => ondoc('gh', t, f);
/*BODY:gh*/

const GS = () => G.persona === 'teacher' ? GS_T
  : DB.myGroups.map(g => ({id: g.id, name: g.name, art: g.art, role: 'lrn', students: 12,
      meta: `${g.bal} ${pl(g.bal, ...g.c)}, ranga ${g.rank}`}));
const ROUTES_OF = {index: () => G.persona === 'teacher' ? 't/groups' : 's/groups', home: () => 't/home', sset: () => 's/group-settings'};
['theme', 'join'].forEach(k => delete ACT[k]);
ACT.go = a => nav(a.dataset.to || (a.dataset.v === 'home' ? 't/home' : a.dataset.v === 'sset' ? 's/group-settings' : G.persona === 'teacher' ? 't/groups' : 's/groups'));
ACT.openGroup = a => (a.dataset.g === 'kk' ? nav(G.persona === 'teacher' ? 't/home' : 's/home') : CORE_ACT.stub(a));

reg('gh', {
  act: ACT, layer,
  closeLayer() { S.modal = null; },
  setView(v) { S.modal = null; S.view = v; S.q = ''; if (v === 'sset') { S.nickIn = DB.me().nick; S.nickErr = null; } },
  page() { setRoute(ROUTES_OF[S.view]()); return `<div class="page">${{index: vIndex, home: vHome, sset: vSset}[S.view]()}</div>`; }
});
})();
