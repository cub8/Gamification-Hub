/* ===== module: auth (from t/auth.html) ===== */
(() => {
const ON = (t, f) => on('auth', t, f), DON = (t, f) => ondoc('auth', t, f);
/*BODY:auth*/

const ROUTES_OF = {login: 'out/login', loginMail: 'out/login-mail', inbox: 'out/inbox', confirm: 'out/link',
  expired: 'out/link-expired', register: 'out/register', regMail: 'out/register-mail', usos: 'out/usos', usosErr: 'out/usos-error'};

delete ACT.theme;
ACT.consume = function () {
  const reg = S.flow === 'register', code = S.f.code || 'Z4KN7Q';
  DB.pendingJoin = (reg || S.qr) ? code : null;
  nav('s/start');
  toast(icon('check') + (reg ? 'Konto założone.' : 'Zalogowano.'));
  if (DB.pendingJoin) setTimeout(() => openLayer('join-nick', {code, v: ''}), 260);
};
ACT.usosGo = function () { DB.pendingJoin = S.qr ? (S.f.code || 'Z4KN7Q') : null; nav('s/start'); toast(icon('check') + 'Zalogowano przez USOS.'); };
ACT.usosTeacher = function () { nav('t/dash'); toast(icon('check') + 'Zalogowano przez USOS jako nauczyciel.'); };

reg('auth', {
  act: ACT,
  setView(v) { S.view = v; S.err = {}; if (v === 'regMail' && S.qr && !S.f.code) S.f.code = 'Z4KN7Q'; if (v === 'inbox' && !S.cool) S.cool = 60; if (v === 'confirm' && !S.email) S.email = 'jan.nowak@example.com'; },
  qr() { S.qr = !S.qr; if (S.qr && S.view === 'regMail' && !S.f.code) S.f.code = 'Z4KN7Q'; render(false); return S.qr; },
  page() {
    setRoute(ROUTES_OF[S.view]);
    const usos = S.view === 'usos';
    return `<div class="tw" style="position:relative;flex:1"><div class="ttint plain"></div><div class="tpat"></div><main class="main" id="main"><div class="auth">
      <div class="brand">${LOGO}<span>Gamification Hub</span></div>
      ${['login', 'loginMail', 'register', 'regMail'].includes(S.view) ? pending() : ''}
      <section class="panel acard">${V[S.view]()}${usos ? `<div class="stack" style="margin-top:6px"><button class="btn" data-act="usosGo">Wróć jako student (makieta)</button><button class="btn sec" data-act="usosTeacher">Wróć jako nauczyciel (makieta)</button></div>` : ''}</section>
      <div class="foot"><button class="linkbtn" data-act="theme" style="font-size:12.5px">${G.theme === 'dark' ? 'Jasny motyw' : 'Ciemny motyw'}</button><span>Pomoc: <a href="#" data-act="hint" style="color:inherit">kontakt</a></span></div>
    </div></main></div>`;
  },
  after() { const f = app.querySelector('[data-focus]'); if (f && G.frame === 'desktop') f.focus({preventScroll: true}); tick(); }
});
})();
