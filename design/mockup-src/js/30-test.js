/* ===== module: test (upload stress test, dev-only, from t/test.html) ===== */
(() => {
const html = (() => {
/*BODY:test*/
})();
reg('test', {
  act: {},
  setView() {},
  page() { return `<main class="main" id="main"><div class="wrap" id="w">${html}</div></main>`; }
});
})();
