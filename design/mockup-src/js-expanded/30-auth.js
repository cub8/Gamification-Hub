/* ===== module: auth (from t/auth.html) ===== */
(() => {
const ON = (t, f) => on('auth', t, f), DON = (t, f) => ondoc('auth', t, f);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
/*SHARED*/
Object.assign(IC,{mail:'<path d="M3 5h18v14H3z"/><path d="M3 5l9 8 9-8"/>',cap:'<path d="M2 9l10-5 10 5-10 5z"/><path d="M6 11v5c0 1.5 3 3 6 3s6-1.5 6-3v-5M22 9v6"/>',alert:'<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 17.5v.5"/>',clock:'<path d="M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z"/><path d="M12 7v5l3 3"/>',shield2:'<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>'});
const icon=(n,c='')=>`<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n]||''}</svg>`;
const svgUrl=s=>`url('data:image/svg+xml;charset=utf-8,${encodeURIComponent(s)}')`;
const CASTLE=svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#2B2440"/><circle cx="126" cy="22" r="9" fill="#F2E3B3"/><path d="M34 90V46h8v-6h6v6h8V30h6v-6h6v6h6v16h8v-6h6v6h8v44z" fill="#6E6480"/></svg>');
const LOGO='<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M12 1h16l11 11v16L28 39H12L1 28V12z" style="fill:var(--item)"/><text x="20" y="25.4" text-anchor="middle" style="font:800 15px Bricolage Grotesque,sans-serif;fill:var(--on-item)">GH</text></svg>';
const CODES={Z4KN7Q:{ok:1,group:'Zakon Algorytmów',org:'Szkoła Podstawowa nr 12 w Gdańsku'},T2KWR7:{err:'Ten kod wygasł. Poproś prowadzącego o nowy.'},Z4QHR9:{err:'Z tego kodu skorzystała już maksymalna liczba osób. Poproś prowadzącego o nowy.'}};
const TAKEN='sebastian.alejandro@example.com';
let S={theme:matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light',frame:'desktop',view:'login',qr:false,flow:'login',email:'',f:{email:'',first:'',last:'',code:'',terms:false},err:{},cool:0,usosErr:'cancel'};
let timer=null;
const normCode=v=>v.toUpperCase().replace(/[\s-]/g,'').slice(0,6);
function codeState(){const c=S.f.code;if(c.length<6)return null;if(/[O0I1L]/.test(c))return {err:'Kody nie zawierają liter O, I, L ani cyfr 0 i 1. Sprawdź, czy nie pomylił się znak.'};return CODES[c]||{err:'Nie znaleźliśmy takiego kodu. Sprawdź go z prowadzącym.'};}
const pending=()=>S.qr?`<div class="pending" role="status"><span class="gthumb" style="background-image:${CASTLE}"></span><span>Po ${S.view.startsWith('reg')||S.view==='register'?'rejestracji':'zalogowaniu'} dołączysz do grupy <b>Zakon Algorytmów</b>. Zapamiętaliśmy kod z kodu QR.</span></div>`:'';
const err=k=>S.err[k]?`<p class="err" id="e-${k}">${icon('alert')}<span>${S.err[k]}</span></p>`:'';
const inp=(k,type,ph,lab,extra='')=>`<div class="fld"><label for="f-${k}">${lab}</label><div class="inp${S.err[k]?' bad':''}${k==='code'?' codein':''}"><input id="f-${k}" type="${type}" data-f="${k}" value="${esc(S.f[k])}" placeholder="${ph}"${S.err[k]?` aria-invalid="true" aria-describedby="e-${k}"`:''} ${extra}></div>${err(k)}</div>`;
/* ---------- screens ---------- */
const V={
 login:()=>`<h1>Zaloguj się</h1><p class="lead">Wybierz sposób, z którego korzystasz na swojej uczelni lub w szkole.</p>
  <div class="stack"><button class="btn" data-act="usos">${icon('cap')}Zaloguj się przez USOS</button><p class="who">Studenci i nauczyciele uczelni</p><div class="or">albo</div><button class="btn sec" data-act="go" data-v="loginMail">${icon('mail')}Zaloguj się e-mailem</button><p class="who">Uczniowie szkół i osoby dodane przez administratora</p></div>
  <p class="alt">Nie masz konta? <button class="linkbtn" data-act="go" data-v="register">Zarejestruj się</button></p>`,
 loginMail:()=>`<button class="linkbtn back" data-act="go" data-v="login">${icon('chevLeft')}Inne sposoby logowania</button><h1>Logowanie e-mailem</h1><p class="lead">Wyślemy Ci link do logowania. Hasło nie jest potrzebne.</p>
  ${inp('email','email','jan.nowak@example.com','Adres e-mail','autocomplete="email" data-focus')}
  <div class="stack"><button class="btn" data-act="sendLogin">Wyślij link</button></div><p class="alt">Nie masz konta? <button class="linkbtn" data-act="go" data-v="register">Zarejestruj się</button></p>`,
 inbox:()=>`<div class="center"><div class="big-ic">${icon('mail')}</div><h1>Sprawdź skrzynkę</h1><p class="lead" style="margin-left:auto;margin-right:auto">Wysłaliśmy link na adres</p><p class="addr">${esc(S.email||'jan.nowak@example.com')}</p>
  <p class="small" style="margin-top:14px">Link działa przez 15 minut. Jeśli go nie widzisz, zajrzyj do folderu Spam.</p>
  <div class="stack"><button class="btn sec" data-act="resend"${S.cool?' disabled':''} id="rs">${S.cool?`Wyślij ponownie za 0:${String(S.cool).padStart(2,'0')}`:'Wyślij link ponownie'}</button><button class="linkbtn" data-act="go" data-v="${S.flow==='register'?'regMail':'loginMail'}">Zmień adres e-mail</button></div></div>`,
 confirm:()=>`<div class="center"><div class="big-ic ok">${icon('check')}</div><h1>${S.flow==='register'?'Dokończ rejestrację':'Potwierdź logowanie'}</h1><p class="lead" style="margin-left:auto;margin-right:auto">${S.flow==='register'?'Zakładasz konto dla':'Logujesz się jako'}</p><p class="addr">${esc(S.email||'jan.nowak@example.com')}</p>
  <div class="stack"><button class="btn" data-act="consume" data-focus>${S.flow==='register'?'Załóż konto i dołącz do grupy':'Zaloguj się'}</button></div>
  <p class="small" style="margin-top:14px;display:flex;gap:8px;align-items:flex-start;text-align:left">${icon('shield2')}<span>Ten dodatkowy krok chroni Twój link przed programami, które automatycznie otwierają linki w wiadomościach. Link działa jeszcze 12 minut.</span></p></div>`,
 expired:()=>`<div class="center"><div class="big-ic bad">${icon('clock')}</div><h1>Ten link już nie działa</h1><p class="lead" style="margin-left:auto;margin-right:auto">Link do logowania działa 15 minut i można go użyć tylko raz. Wyślemy Ci nowy.</p>
  <div class="stack"><button class="btn" data-act="go" data-v="loginMail">Wyślij nowy link</button><button class="linkbtn" data-act="go" data-v="login">Wróć do logowania</button></div></div>`,
 register:()=>`<h1>Załóż konto</h1><p class="lead">Wybierz drogę zależnie od tego, gdzie się uczysz.</p>
  <div class="stack"><button class="btn" data-act="usos">${icon('cap')}Zarejestruj się przez USOS</button><p class="who">Studenci uczelni. Konto powstanie przy pierwszym logowaniu.</p><div class="or">albo</div><button class="btn sec" data-act="go" data-v="regMail">${icon('mail')}Zarejestruj się e-mailem</button><p class="who">Uczniowie szkół. Potrzebujesz kodu od prowadzącego.</p></div>
  <p class="alt">Masz już konto? <button class="linkbtn" data-act="go" data-v="login">Zaloguj się</button></p>`,
 regMail:()=>{const cs=codeState();return `<button class="linkbtn back" data-act="go" data-v="register">${icon('chevLeft')}Inne sposoby rejestracji</button><h1>Rejestracja e-mailem</h1><p class="lead">Kod od prowadzącego potwierdza zaproszenie i od razu dodaje Cię do właściwej szkoły i grupy.</p>
  ${inp('code','text','np. Z4KN7Q','Kod zaproszenia','maxlength="8" autocomplete="off" autocapitalize="characters" spellcheck="false"'+(S.qr?'':' data-focus'))}
  <div id="cprev">${cs&&cs.ok?`<div class="gprev2 oct" style="--c:8px"><span class="gthumb" style="background-image:${CASTLE}"></span><span><b>${cs.group}</b><small>${cs.org}</small></span>${icon('check')}</div>`:cs&&!S.err.code?`<p class="err">${icon('alert')}<span>${cs.err}</span></p>`:''}</div>
  <div class="row2b">${inp('first','text','Jan','Imię','autocomplete="given-name"')}${inp('last','text','Nowak','Nazwisko','autocomplete="family-name"')}</div>
  ${inp('email','email','jan.nowak@example.com','Adres e-mail','autocomplete="email"'+(S.qr?' data-focus':''))}
  <label class="chk"><input type="checkbox" data-f="terms"${S.f.terms?' checked':''}${S.err.terms?' aria-invalid="true" aria-describedby="e-terms"':''}><span>Akceptuję <a href="#" data-act="hint">regulamin</a> i <a href="#" data-act="hint">politykę prywatności</a>.</span></label>${err('terms')}
  <div class="stack"><button class="btn" data-act="register">Załóż konto</button></div><p class="alt">Masz już konto? <button class="linkbtn" data-act="go" data-v="login">Zaloguj się</button></p>`;},
 usos:()=>`<div class="center"><div class="loader" aria-hidden="true"></div><h1>Przekierowujemy do USOS</h1><p class="lead" style="margin-left:auto;margin-right:auto">Zaloguj się tam tak jak zwykle. Potem wrócisz tutaj automatycznie.</p>
  <p class="small" style="margin-top:14px">Nic się nie dzieje? <button class="linkbtn" data-act="usosErr">Otwórz USOS ręcznie</button></p></div>`,
 usosErr:()=>`<div class="center"><div class="big-ic bad">${icon('alert')}</div>${S.usosErr==='cancel'?`<h1>Logowanie przerwane</h1><p class="lead" style="margin-left:auto;margin-right:auto">Anulowano logowanie w USOS albo nie udzielono zgody na dostęp do danych. Bez tego nie możemy założyć ani otworzyć konta.</p>`
  :`<h1>USOS nie odpowiada</h1><p class="lead" style="margin-left:auto;margin-right:auto">To problem po stronie USOS. Spróbuj za kilka minut.</p>`}
  <div class="stack"><button class="btn" data-act="usos">Spróbuj ponownie</button><button class="linkbtn" data-act="go" data-v="login">Wróć do logowania</button></div></div>`};
/* ---------- render ---------- */
function tick(){clearInterval(timer);if(S.view==='inbox'&&S.cool>0)timer=setInterval(()=>{S.cool--;const b=app.querySelector('#rs');if(!b){clearInterval(timer);return;}if(S.cool<=0){clearInterval(timer);b.disabled=false;b.textContent='Wyślij link ponownie';}else b.textContent=`Wyślij ponownie za 0:${String(S.cool).padStart(2,'0')}`;},1000);}
const mailOk=v=>/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
function go(v){S.view=v;S.err={};if(v==='regMail'&&S.qr&&!S.f.code)S.f.code='Z4KN7Q';if(v==='inbox'&&!S.cool)S.cool=60;render();}
const ACT={theme(){G.theme=G.theme==='dark'?'light':'dark';render();},hint(){hint('Terms and privacy policy don’t exist yet (flagged for the client).');},go(a){go(a.dataset.v);},
 usos(){go('usos');},usosErr(){S.usosErr='cancel';go('usosErr');},flipErr(){S.usosErr=S.usosErr==='cancel'?'down':'cancel';render();},
 sendLogin(){const e=S.f.email.trim();S.err={};if(!mailOk(e)){S.err.email=e?'To nie wygląda na adres e-mail. Sprawdź, czy jest w nim @ i domena.':'Podaj adres e-mail.';render();app.querySelector('#f-email').focus();return;}S.email=e;S.flow='login';S.cool=60;go('inbox');},
 resend(){S.cool=60;render();toast(icon('mail')+'Wysłaliśmy nowy link. Poprzedni już nie działa.');},
 consume(){toast(icon('check')+(S.flow==='register'?'Konto założone. Dołączono do grupy Zakon Algorytmów.':'Zalogowano.'+(S.qr?' Dołączono do grupy Zakon Algorytmów.':'')));hint('Would continue to the student start page (or the pending group).');},
 register(){const f=S.f,cs=codeState();S.err={};
  if(!f.code)S.err.code='Podaj kod zaproszenia od prowadzącego.';else if(f.code.length<6)S.err.code='Kod ma 6 znaków.';else if(!cs.ok)S.err.code=cs.err;
  if(!f.first.trim())S.err.first='Podaj imię.';if(!f.last.trim())S.err.last='Podaj nazwisko.';
  if(!mailOk(f.email.trim()))S.err.email=f.email.trim()?'To nie wygląda na adres e-mail.':'Podaj adres e-mail.';
  else if(f.email.trim().toLowerCase()===TAKEN)S.err.email='Masz już konto z tym adresem. <button class="linkbtn" data-act="go" data-v="loginMail">Zaloguj się</button>';
  if(!f.terms)S.err.terms='Zaakceptuj regulamin i politykę prywatności, żeby założyć konto.';
  if(Object.keys(S.err).length){render();const x=app.querySelector('[aria-invalid="true"]');if(x)x.focus();return;}S.email=f.email.trim();S.flow='register';S.cool=60;go('inbox');}};
ON('input',e=>{const t=e.target,k=t.dataset.f;if(!k)return;
 if(k==='terms'){S.f.terms=t.checked;return;}
 if(k==='code'){const v=normCode(t.value);if(v!==t.value)t.value=v;S.f.code=v;delete S.err.code;const cs=codeState(),p=app.querySelector('#cprev');
  t.parentNode.classList.toggle('bad',!!(cs&&cs.err));p.innerHTML=cs&&cs.ok?`<div class="gprev2 oct" style="--c:8px"><span class="gthumb" style="background-image:${CASTLE}"></span><span><b>${cs.group}</b><small>${cs.org}</small></span>${icon('check')}</div>`:cs?`<p class="err">${icon('alert')}<span>${cs.err}</span></p>`:'';const em=app.querySelector('#e-code');if(em)em.remove();return;}
 S.f[k]=t.value;if(S.err[k]){delete S.err[k];t.parentNode.classList.remove('bad');t.removeAttribute('aria-invalid');const m=app.querySelector('#e-'+k);if(m)m.remove();}});
ON('keydown',e=>{if(e.key==='Enter'&&e.target.dataset.f&&e.target.type!=='checkbox'){e.preventDefault();S.view==='loginMail'?ACT.sendLogin():S.view==='regMail'&&ACT.register();}});

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
