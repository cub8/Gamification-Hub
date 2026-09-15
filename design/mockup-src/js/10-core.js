/* ===== core: state, hash router, chrome, layers, toolbar ===== */
const app = document.getElementById('app');
const device = document.getElementById('device');
const stage = document.getElementById('stage');

const G = {
  persona: 'out',
  theme: (window.matchMedia && matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light',
  frame: 'desktop', route: 'out/login', collapsed: false, layer: null, offline: false
};
const isMobile = () => device.offsetWidth <= 720;
const user = () => G.persona === 'teacher' ? {name: DB.teacher.name, role: 'teacher'} : {name: DB.me().name, role: 'student'};

/* ---------- item pricing / availability (shared by shop, forms, student pages) ---------- */
function itemState(it, st) {
  st = st || DB.me();
  const reasons = [];
  if (it.req && it.req.rank != null && rankIdx(st.tot) < it.req.rank) reasons.push({t: 'rank', r: RANKS[it.req.rank]});
  ((it.req && it.req.badges) || []).forEach(b => { if (!st.badges.includes(b)) reasons.push({t: 'badge', b: BADGE[b]}); });
  if (st.lives === 0 && !it.zeroLives) reasons.push({t: 'lives'});
  const pct = (it.discBadges || []).filter(b => st.badges.includes(b)).reduce((a, b) => a + BADGE[b].disc, 0);
  const price = Math.round(it.cost * (1 - pct / 100));
  const state = reasons.length ? 'sealed' : (price <= st.bal ? 'afford' : 'save');
  return {state, reasons, pct, price, missing: Math.max(0, price - st.bal)};
}
const discNames = it => (it.discBadges || []).filter(b => DB.me().badges.includes(b)).map(b => BADGE[b].name);
function reqText(r) {
  if (r.t === 'rank') return `Wymaga rangi <b>${esc(r.r.name)}</b>. Zebrane: ${DB.me().tot} z ${r.r.min}.`;
  if (r.t === 'badge') return `Wymaga odznaki <b>${esc(r.b.name)}</b>.`;
  return 'Masz 0 żyć. Najpierw odzyskaj życie.';
}
const sealLabel = r => r.t === 'rank' ? `Od rangi ${r.r.name}` : r.t === 'badge' ? `Za odznakę ${r.b.name}` : 'Niedostępne przy 0 życiach';
const shopItems = () => ITEMS.filter(it => !DB.soldOut[it.id]);

/* ---------- modules ---------- */
const MODS = {};
const reg = (id, m) => { MODS[id] = m; };
const curMod = () => MODS[(ROUTE[G.route] || {}).mod] || null;

/* ---------- routes ----------
   id = persona/slug ; hash = #/persona/slug                                   */
const R = (id, o) => Object.assign(ROUTE, {[id]: Object.assign({id, persona: id.split('/')[0]}, o)});
const ROUTE = {};
[
  /* logged out */
  ['out/login', {mod: 'auth', view: 'login', label: 'Logowanie', chrome: 'none'}],
  ['out/login-mail', {mod: 'auth', view: 'loginMail', label: 'Logowanie e-mailem', chrome: 'none'}],
  ['out/inbox', {mod: 'auth', view: 'inbox', label: 'Sprawdź skrzynkę', chrome: 'none'}],
  ['out/link', {mod: 'auth', view: 'confirm', label: 'Strona magic linku', chrome: 'none'}],
  ['out/link-expired', {mod: 'auth', view: 'expired', label: 'Link wygasł', chrome: 'none'}],
  ['out/register', {mod: 'auth', view: 'register', label: 'Rejestracja', chrome: 'none'}],
  ['out/register-mail', {mod: 'auth', view: 'regMail', label: 'Rejestracja e-mailem', chrome: 'none'}],
  ['out/usos', {mod: 'auth', view: 'usos', label: 'Przekierowanie do USOS', chrome: 'none'}],
  ['out/usos-error', {mod: 'auth', view: 'usosErr', label: 'Błąd USOS', chrome: 'none'}],

  /* student */
  ['s/start', {mod: 'isg', view: 'start', label: 'Start studenta', chrome: 'app', bg: 'plain', sec: 'start'}],
  ['s/groups', {mod: 'gh', view: 'index', label: 'Moje grupy', chrome: 'app', bg: 'plain', sec: 'groups'}],
  ['s/home', {mod: 'main', view: 'home', label: 'Grupa: przegląd', chrome: 'group', sec: 's/home'}],
  ['s/shop', {mod: 'main', view: 'shop', label: 'Sklep', chrome: 'group', sec: 's/shop'}],
  ['s/my-items', {mod: 'sp', view: 'items', label: 'Moje przedmioty', chrome: 'group', sec: 's/my-items'}],
  ['s/ranks', {mod: 'sp', view: 'ranks', label: 'Rangi', chrome: 'group', sec: 's/ranks'}],
  ['s/badges', {mod: 'sp', view: 'badges', label: 'Odznaki', chrome: 'group', sec: 's/badges'}],
  ['s/history', {mod: 'sp', view: 'hist', label: 'Historia waluty', chrome: 'group', sec: 's/history'}],
  ['s/ranking', {mod: 'rk', view: 'rs', label: 'Ranking', chrome: 'group', sec: 's/ranking'}],
  ['s/group-settings', {mod: 'gh', view: 'sset', label: 'Ustawienia w grupie', chrome: 'group', sec: 's/group-settings'}],
  ['s/account', {mod: 'core', view: 'account', label: 'Ustawienia konta', chrome: 'app', bg: 'plain'}],

  /* teacher */
  ['t/dash', {mod: 'main', view: 'dash', label: 'Start nauczyciela', chrome: 'app', bg: 'plain', sec: 'start'}],
  ['t/groups', {mod: 'gh', view: 'index', label: 'Wszystkie grupy', chrome: 'app', bg: 'plain', sec: 'groups'}],
  ['t/home', {mod: 'gh', view: 'home', label: 'Grupa: przegląd', chrome: 'group', sec: 't/home'}],
  ['t/students', {mod: 'lists', view: 'students', label: 'Studenci', chrome: 'group', sec: 't/students'}],
  ['t/student', {mod: 'student', view: 'one', label: 'Student: szczegóły', chrome: 'group', sec: 't/students'}],
  ['t/sheets', {mod: 'ag', view: 'list', label: 'Arkusze ocen', chrome: 'group', sec: 't/sheets'}],
  ['t/sheet-template-new', {mod: 'ag', view: 'newtpl', label: 'Nowy szablon arkusza', chrome: 'focus', sec: 't/sheets', pad0: 1}],
  ['t/sheet-template-edit', {mod: 'ag', view: 'edittpl', label: 'Edycja szablonu', chrome: 'focus', sec: 't/sheets', pad0: 1}],
  ['t/sheet-settings', {mod: 'ag', view: 'group', label: 'Ustawienia arkusza', chrome: 'focus', sec: 't/sheets', pad0: 1}],
  ['t/grade', {mod: 'main', view: 'grade', label: 'Ocenianie (arkusz)', chrome: 'group', sec: 't/sheets'}],
  ['t/items', {mod: 'lists', view: 'items', label: 'Przedmioty', chrome: 'group', sec: 't/items'}],
  ['t/item-new', {mod: 'item', view: 'create', label: 'Nowy przedmiot', chrome: 'focus', sec: 't/items', pad0: 1}],
  ['t/item-edit', {mod: 'item', view: 'edit', label: 'Edycja przedmiotu', chrome: 'focus', sec: 't/items', pad0: 1}],
  ['t/ranks', {mod: 'lists', view: 'ranks', label: 'Rangi', chrome: 'group', sec: 't/ranks'}],
  ['t/rank-new', {mod: 'br', view: 'rank-create', label: 'Nowa ranga', chrome: 'focus', sec: 't/ranks', pad0: 1}],
  ['t/rank-edit', {mod: 'br', view: 'rank-edit', label: 'Edycja rangi', chrome: 'focus', sec: 't/ranks', pad0: 1}],
  ['t/badges', {mod: 'lists', view: 'badges', label: 'Odznaki', chrome: 'group', sec: 't/badges'}],
  ['t/badge-new', {mod: 'br', view: 'badge-create', label: 'Nowa odznaka', chrome: 'focus', sec: 't/badges', pad0: 1}],
  ['t/badge-edit', {mod: 'br', view: 'badge-edit', label: 'Edycja odznaki', chrome: 'focus', sec: 't/badges', pad0: 1}],
  ['t/ranking', {mod: 'rk', view: 'rt', label: 'Ranking', chrome: 'group', sec: 't/ranking'}],
  ['t/invites', {mod: 'isg', view: 'inv', label: 'Zaproszenia', chrome: 'group', sec: 't/invites'}],
  ['t/teachers', {mod: 'rk', view: 'teachers', label: 'Nauczyciele', chrome: 'group', sec: 't/teachers'}],
  ['t/group-settings', {mod: 'isg', view: 'set', label: 'Ustawienia grupy', chrome: 'focus', sec: 't/group-settings', pad0: 1}],
  ['t/purchases', {mod: 'core', view: 'purchases', label: 'Wszystkie zakupy w grupie', chrome: 'group', sec: 't/home'}],
  ['t/new-group', {mod: 'form', view: 'wizard', label: 'Nowa grupa (kreator)', chrome: 'focus', bg: 'plain'}],
  ['t/account', {mod: 'core', view: 'account', label: 'Ustawienia konta', chrome: 'app', bg: 'plain'}],

  /* states / dev */
  ['s/loading', {mod: 'sp', view: 'loading', label: 'Ładowanie (szkielety)', chrome: 'group', sec: 's/my-items'}],
  ['s/error', {mod: 'core', view: 'error', label: 'Błąd serwera / offline', chrome: 'group'}],
  ['s/states', {mod: 'sp', view: 'states', label: 'Galeria stanów (dev)', chrome: 'group', sec: 's/my-items'}],
  ['t/uploads', {mod: 'test', view: 'test', label: 'Test uploadów (dev)', chrome: 'none'}]
].forEach(([id, o]) => R(id, o));

const DEFAULT_ROUTE = {out: 'out/login', student: 's/home', teacher: 't/dash'};

/* ---------- navigation ---------- */
function nav(id, opt) {
  const r = ROUTE[id]; if (!r) { hint('No route: ' + id); return; }
  G.persona = r.persona === 'out' ? 'out' : (r.persona === 's' ? 'student' : 'teacher');
  G.route = id; G.layer = null;
  const m = MODS[r.mod];
  if (m && m.setView) m.setView(r.view, opt || {});
  location.hash = '#/' + id;
  render(false);
  const mn = app.querySelector('.main'); if (mn) mn.scrollTop = 0;
}
/* modules that flip their own sub-view call this from page() so hash + toolbar stay in sync */
function setRoute(id) {
  if (!ROUTE[id] || G.route === id) return;
  G.route = id;
  const p = ROUTE[id].persona;
  G.persona = p === 'out' ? 'out' : (p === 's' ? 'student' : 'teacher');
  location.hash = '#/' + id;
}
function fromHash() {
  const id = (location.hash || '').replace(/^#\/?/, '');
  return ROUTE[id] ? id : null;
}
function setPersona(p) { nav(DEFAULT_ROUTE[p]); }

/* ---------- chrome ---------- */
const NAV_G = () => G.persona === 'teacher'
  ? [{l: 'Start', i: 'home', to: 't/dash'}, {l: 'Grupy', i: 'cards', to: 't/groups'}]
  : [{l: 'Start', i: 'home', to: 's/start'}, {l: 'Grupy', i: 'cards', to: 's/groups'}];
const NAV_T = [
  {l: 'Przegląd', i: 'overview', to: 't/home'}, {l: 'Studenci', i: 'users', to: 't/students'},
  {l: 'Arkusze ocen', i: 'grid', to: 't/sheets'}, {l: 'Przedmioty', i: 'chest', to: 't/items'},
  {l: 'Rangi', i: 'rank', to: 't/ranks'}, {l: 'Odznaki', i: 'badge', to: 't/badges'},
  {l: 'Ranking', i: 'podium', to: 't/ranking'}, {l: 'Zaproszenia', i: 'qr', to: 't/invites'},
  {l: 'Nauczyciele', i: 'briefcase', to: 't/teachers'}, {l: 'Ustawienia grupy', i: 'settings', to: 't/group-settings'}
];
const NAV_S = [
  {l: 'Przegląd', i: 'overview', to: 's/home'}, {l: 'Sklep', i: 'bag', to: 's/shop'},
  {l: 'Moje przedmioty', i: 'chest', to: 's/my-items'}, {l: 'Rangi', i: 'rank', to: 's/ranks'},
  {l: 'Odznaki', i: 'badge', to: 's/badges'}, {l: 'Historia waluty', i: 'history', to: 's/history'},
  {l: 'Ranking', i: 'podium', to: 's/ranking'}, {l: 'Ustawienia w grupie', i: 'settings', to: 's/group-settings'}
];
const secOf = () => (ROUTE[G.route] || {}).sec || '';
const nl = l => {
  const on = l.to === G.route || l.to === secOf();
  return `<a href="#/${l.to}" class="nl${on ? ' on' : ''}" data-act="nav" data-to="${l.to}" title="${esc(l.l)}"${on ? ' aria-current="page"' : ''}>${icon(l.i)}<span>${esc(l.l)}</span></a>`;
};
const inGroup = () => { const r = ROUTE[G.route] || {}; return r.chrome === 'group' || (r.chrome === 'focus' && !!r.sec); };

function header() {
  const u = user(), g = GROUP.kk, st = DB.me(), unread = DB.unread();
  return `<header class="hd">
    <a href="#/${G.persona === 'teacher' ? 't/dash' : 's/start'}" class="logo" data-act="nav" data-to="${G.persona === 'teacher' ? 't/dash' : 's/start'}" aria-label="Gamification Hub, start">${LOGO}<span class="logo-word">Gamification Hub</span></a>
    ${inGroup() ? `<button class="gsw" data-act="switch" aria-label="Grupa ${esc(g.name)}, zmień grupę">${gthumb(g)}<span class="gsw-name">${esc(g.name)}</span>${icon('chevDown')}</button>` : ''}
    <span class="sp"></span>
    ${u.role === 'student' && inGroup() ? `<button class="bal" data-act="nav" data-to="s/history" title="${st.bal} do wydania, ${st.tot} zebrane łącznie" aria-label="Masz ${st.bal} ${curA(st.bal)} do wydania">${coin('carrot')}<span><b>${st.bal}</b><small>do wydania</small></span></button>` : ''}
    ${u.role === 'student' ? `<button class="btn sec hd-join" data-act="join" aria-label="Dołącz do grupy">${icon('plus')}<span>Dołącz do grupy</span></button>` : ''}
    <button class="iconbtn hd-theme" data-act="theme" aria-label="Przełącz motyw">${icon('moon', 'ic-moon')}${icon('sun', 'ic-sun')}</button>
    ${u.role === 'teacher' ? `<button class="iconbtn" data-act="bell" aria-expanded="${G.layer === 'notif'}" aria-label="Powiadomienia${unread ? `, ${unread} nowe` : ''}">${icon('bell')}${unread ? `<span class="count">${unread}</span>` : ''}</button>` : ''}
    <button class="av-btn" data-act="avatar" aria-label="Konto: ${esc(u.name)}">${avatar(u.name)}</button>
  </header>`;
}
function sidebar() {
  const u = user();
  let mid = '';
  if (inGroup()) {
    const g = GROUP.kk;
    mid = `<section class="deck" aria-label="Grupa ${esc(g.name)}"><div class="deck-f"><div class="deck-i">
      <span class="deck-art" style="background-image:${ART[g.art]}" aria-hidden="true"></span>
      <div class="deck-head"><h2 class="deck-name">${esc(g.name)}</h2><p class="deck-role">${u.role === 'student' ? 'Jesteś uczestnikiem' : 'Prowadzisz tę grupę'}</p>
        <button class="linkbtn deck-sw" data-act="switch">${icon('switch')}Zmień grupę</button></div>
      <nav class="nav" aria-label="Sekcje grupy">${(u.role === 'student' ? NAV_S : NAV_T).map(nl).join('')}</nav>
    </div></div></section>`;
  } else if (u.role === 'teacher') {
    mid = `<p class="sb-sec">Twoje grupy</p><div class="glist">${GROUPS.map(g => `<a href="#" class="gl" data-act="${g.id === 'kk' ? 'nav' : 'stub'}" data-to="t/home" data-g="${g.id}" title="${esc(g.name)}">${gthumb(g)}<span class="gl-t"><b>${esc(g.name)}</b><small>${g.role === 'owner' ? 'Prowadzisz' : 'Wspierasz'}, ${g.students} ${pl(g.students, 'student', 'studentów', 'studentów')}</small></span></a>`).join('')}</div>`;
  } else {
    mid = `<p class="sb-sec">Twoje grupy</p><div class="glist">${DB.myGroups.map(g => `<a href="#" class="gl" data-act="${g.id === 'kk' ? 'nav' : 'stub'}" data-to="s/home" data-g="${g.id}" title="${esc(g.name)}">${g.art && ART[g.art] ? `<span class="gthumb" style="background-image:${ART[g.art]}"></span>` : `<span class="gthumb nart">${esc(g.name.slice(0, 2).toUpperCase())}</span>`}<span class="gl-t"><b>${esc(g.name)}</b><small>Prowadzi ${esc(g.teacher)}</small></span></a>`).join('')}</div>`;
  }
  return `<aside class="sb${G.collapsed ? ' collapsed' : ''}">
    <nav class="nav nav-g" aria-label="Główna">${NAV_G().map(nl).join('')}</nav>
    ${mid}
    <div class="sb-foot"><button class="sb-col" data-act="collapse" aria-expanded="${!G.collapsed}">${icon(G.collapsed ? 'chevRight' : 'chevLeft')}<span>${G.collapsed ? 'Rozwiń' : 'Zwiń panel'}</span></button></div>
  </aside>`;
}
function tabbar() {
  const r = ROUTE[G.route] || {}, t = G.persona === 'teacher';
  if (r.chrome === 'focus' || r.chrome === 'none') return '';
  const tabs = inGroup()
    ? (t ? [{l: 'Przegląd', i: 'overview', to: 't/home'}, {l: 'Studenci', i: 'users', to: 't/students'}, {l: 'Arkusze', i: 'grid', to: 't/sheets'}, {l: 'Więcej', i: 'more', act: 'more'}]
         : [{l: 'Przegląd', i: 'overview', to: 's/home'}, {l: 'Sklep', i: 'bag', to: 's/shop'}, {l: 'Przedmioty', i: 'chest', to: 's/my-items'}, {l: 'Ranking', i: 'podium', to: 's/ranking'}, {l: 'Więcej', i: 'more', act: 'more'}])
    : (t ? [{l: 'Start', i: 'home', to: 't/dash'}, {l: 'Grupy', i: 'cards', to: 't/groups'}, {l: 'Powiadomienia', i: 'bell', act: 'bell'}, {l: 'Więcej', i: 'more', act: 'more'}]
         : [{l: 'Start', i: 'home', to: 's/start'}, {l: 'Grupy', i: 'cards', to: 's/groups'}, {l: 'Więcej', i: 'more', act: 'more'}]);
  const sec = secOf();
  return `<nav class="tabbar" aria-label="Nawigacja">${tabs.map(x => { const on = x.to && (x.to === G.route || x.to === sec); return `<a href="${x.to ? '#/' + x.to : '#'}" class="tab${on ? ' on' : ''}" data-act="${x.act || 'nav'}" data-to="${x.to || ''}"${on ? ' aria-current="page"' : ''}>${icon(x.i)}<span>${x.l}</span></a>`; }).join('')}</nav>`;
}

/* ---------- core-owned pages (gaps) ---------- */
function pageAccount() {
  const t = G.persona === 'teacher', u = t ? DB.teacher : DB.me();
  const rows = t
    ? [['Imię i nazwisko', u.name], ['E-mail', u.email], ['Uczelnia', 'Politechnika Gdańska'], ['Identyfikator USOS', DB.teacher.usos], ['Rola', 'Nauczyciel']]
    : [['Imię i nazwisko', u.name], ['E-mail', u.email], ['Uczelnia', 'Politechnika Gdańska'], ['Numer indeksu', u.index], ['Identyfikator USOS', '—'], ['Rola', 'Student']];
  return `<div class="page"><section class="panel phead"><div class="phead-t"><h1>Ustawienia</h1>
    <p class="lead">Twoje dane pochodzą z uczelni i zmienia się je w USOS. Tutaj ustawisz motyw i wylogujesz się.</p></div></section>
    <section class="panel acc"><h2 class="h2">Dane konta</h2>
      <dl class="acc-dl">${rows.map(([k, v]) => `<div><dt>${k}</dt><dd>${esc(String(v))}</dd></div>`).join('')}</dl>
      <p class="expl">${icon('lock')}Danych nie zmienisz w aplikacji. Jeśli coś się nie zgadza, popraw je w USOS albo napisz do prowadzącego.</p>
    </section>
    <section class="panel acc"><h2 class="h2">Wygląd</h2>
      <div class="seg3" role="group" aria-label="Motyw"><button data-act="settheme" data-t="light" aria-pressed="${G.theme === 'light'}">${icon('sun')}Jasny</button><button data-act="settheme" data-t="dark" aria-pressed="${G.theme === 'dark'}">${icon('moon')}Ciemny</button></div>
    </section>
    <section class="panel acc"><h2 class="h2">Konto</h2>
      <button class="btn sec" data-act="logout">${icon('logout')}Wyloguj się</button>
    </section></div>`;
}
function pagePurchases() {
  const list = DB.purch.filter(p => p.g === 'kk');
  const row = p => { const it = pItem(p); return `<li class="prow${p.fresh ? ' fresh' : ''}">${miniCard(it.glyph)}<span class="p-main"><b>${esc(it.name)}</b><span>${esc(p.stu)}</span></span>${costChip(p.price, null, 'carrot', 'sm')}<span class="p-time">${p.time}</span></li>`; };
  return `<div class="page"><section class="panel phead"><div class="phead-t"><p class="crumbs"><a href="#/t/home" data-act="nav" data-to="t/home">Kosmiczne króliki</a>${icon('chevRight')}<span>Zakupy</span></p><h1>Wszystkie zakupy w grupie</h1>
    <p class="lead">${list.length} ${pl(list.length, 'zakup', 'zakupy', 'zakupów')} w grupie Kosmiczne króliki. Przedmioty usunięte z oferty zostają w historii.</p></div></section>
    <section class="panel purch" style="margin-top:22px">
      ${['Dziś', 'Wczoraj', 'Wcześniej'].map(d => { const rows = list.filter(p => p.day === d); return rows.length ? `<h3 class="day">${d}</h3><ul class="plist">${rows.map(row).join('')}</ul>` : ''; }).join('')}
    </section></div>`;
}
function pageError() {
  return `<div class="page"><section class="panel gm err-p">
    <div class="gm-ic oct">${icon('alert')}</div>
    <h1 class="h2">${G.offline ? 'Brak połączenia' : 'Coś poszło nie tak'}</h1>
    <p class="lead">${G.offline ? 'Nie mamy teraz kontaktu z serwerem. Sprawdź połączenie i spróbuj ponownie — nic nie przepadło.' : 'Serwer nie odpowiedział na to żądanie. Spróbuj ponownie za chwilę.'}</p>
    <p class="small">Jeśli to się powtarza, napisz do prowadzącego albo do pomocy technicznej.</p>
    <div class="dlg-b" style="justify-content:center"><button class="btn" data-act="retry">${icon('history')}Spróbuj ponownie</button><button class="btn sec" data-act="nav" data-to="${G.persona === 'teacher' ? 't/dash' : 's/home'}">Wróć na start</button></div>
  </section></div>`;
}
reg('core', {
  page() { const v = (ROUTE[G.route] || {}).view; return v === 'account' ? pageAccount() : v === 'purchases' ? pagePurchases() : pageError(); },
  act: {
    settheme(a) { setTheme(a.dataset.t); render(true); },
    retry() { G.offline = false; toast(icon('check') + 'Połączono ponownie.'); nav(G.persona === 'teacher' ? 't/dash' : 's/home'); }
  }
});

/* ---------- layers (core popovers, sheets, dialogs) ---------- */
const ovl = (inner, cls = '') => `<div class="ovl ${cls}" data-act="close">${inner}</div>`;
const pop = (inner, cls = '') => `<div class="pop-ovl" data-act="close"><div class="pop-w ${cls}" data-act="noop"><div class="pop">${inner}</div></div></div>`;
const cdlg = (inner, label, cls = '') => `<div class="dlg ${cls}" role="dialog" aria-modal="true" aria-labelledby="${label}" data-act="noop"><div class="dlg-in"><span class="grab" aria-hidden="true"></span>${inner}</div></div>`;

function popNotif() {
  const rows = DB.notes.slice(0, 4);
  const row = (n, i) => {
    const it = n.item ? ITEM[n.item] : {name: n.name, glyph: n.glyph}, g = GROUP[n.g];
    return `<li class="nrow${n.u ? ' un' : ''}" data-act="readN" data-i="${i}" tabindex="0" role="button">${miniCard(it.glyph)}<span><b>${esc(n.stu)}</b><span>Zakup: ${esc(it.name)}</span><small>${esc(g.name)}, ${esc(n.when)}</small></span>${n.u ? '<span class="dot" aria-label="nowe"></span>' : ''}</li>`;
  };
  const nw = rows.map((n, i) => [n, i]).filter(([n]) => n.u), old = rows.map((n, i) => [n, i]).filter(([n]) => !n.u);
  return `<div class="pop-h"><h2 class="h3">Powiadomienia</h2>${DB.unread() ? `<button class="linkbtn" data-act="readAll">${icon('checks')}Oznacz wszystkie</button>` : ''}</div>
    ${nw.length ? `<p class="pop-sec">Nowe</p><ul class="nlist">${nw.map(([n, i]) => row(n, i)).join('')}</ul>` : ''}
    ${old.length ? `<p class="pop-sec">Wcześniej</p><ul class="nlist">${old.map(([n, i]) => row(n, i)).join('')}</ul>` : ''}
    <div class="pop-f"><button class="btn sec" data-act="nav" data-to="t/purchases">Wszystkie zakupy w grupie</button></div>`;
}
function popAvatar() {
  const u = user();
  return `<div class="pop-me">${avatar(u.name)}<span><b>${esc(u.name)}</b><small>${u.role === 'student' ? 'Student' : 'Nauczyciel'}</small></span></div>
    <ul class="menu"><li><button data-act="theme">${icon(G.theme === 'dark' ? 'sun' : 'moon')}${G.theme === 'dark' ? 'Włącz jasny motyw' : 'Włącz ciemny motyw'}</button></li>
    <li><button data-act="nav" data-to="${G.persona === 'teacher' ? 't/account' : 's/account'}">${icon('settings')}Ustawienia</button></li>
    <li><button data-act="logout">${icon('logout')}Wyloguj się</button></li></ul>`;
}
function popSwitch() {
  const list = G.persona === 'teacher' ? GROUPS.map(g => ({id: g.id, name: g.name, art: g.art})) : DB.myGroups;
  return `<div class="pop-h"><h2 class="h3">Zmień grupę</h2></div><ul class="menu">${list.map(g => { const cur = g.id === 'kk';
    return `<li><button data-act="${cur ? 'close' : 'stub'}" data-g="${g.id}">${g.art && ART[g.art] ? `<span class="gthumb" style="background-image:${ART[g.art]}"></span>` : `<span class="gthumb nart">${esc(g.name.slice(0, 2).toUpperCase())}</span>`}<span>${esc(g.name)}</span>${cur ? '<span class="cur">Tu jesteś</span>' : ''}</button></li>`; }).join('')}</ul>
    ${G.persona === 'student' ? `<div class="pop-f"><button class="btn sec" data-act="join">${icon('plus')}Dołącz do grupy</button></div>` : ''}`;
}
function sheetMore() {
  const u = user(), items = inGroup() ? (u.role === 'teacher' ? NAV_T : NAV_S) : (u.role === 'teacher' ? [{l: 'Nowa grupa', i: 'plus', to: 't/new-group'}] : []);
  const extra = [{l: 'Ustawienia konta', i: 'settings', to: u.role === 'teacher' ? 't/account' : 's/account'}];
  return cdlg(`<h2 class="h2" id="mo">Więcej</h2>
    <ul class="menu more-m">${items.map(x => `<li><button data-act="nav" data-to="${x.to}"${x.to === G.route ? ' aria-current="page"' : ''}>${icon(x.i)}<span>${esc(x.l)}</span></button></li>`).join('')}</ul>
    <p class="pop-sec">Konto</p>
    <ul class="menu more-m">${extra.map(x => `<li><button data-act="nav" data-to="${x.to}">${icon(x.i)}<span>${esc(x.l)}</span></button></li>`).join('')}
      <li><button data-act="theme">${icon(G.theme === 'dark' ? 'sun' : 'moon')}<span>${G.theme === 'dark' ? 'Jasny motyw' : 'Ciemny motyw'}</span></button></li>
      <li><button data-act="logout">${icon('logout')}<span>Wyloguj się</span></button></li></ul>
    <div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Zamknij</button></div>`, 'mo', 'dlg-sheet');
}
function dlgJoin() {
  return cdlg(`<p class="small" style="margin-bottom:4px">Krok 1 z 2</p><h2 class="h2" id="jt">Dołącz do grupy</h2><p>Wpisz 6-znakowy kod, który podał prowadzący.</p>
    <div class="code" role="group" aria-label="Kod zaproszenia">${[0, 1, 2, 3, 4, 5].map(k => `<span class="slot"><input data-slot="${k}" maxlength="2" autocomplete="off" autocapitalize="characters" spellcheck="false" aria-label="Znak ${k + 1} z 6"${k === 0 ? ' data-focus' : ''}></span>`).join('')}</div>
    <p class="small hint-q">${icon('camera')}Masz kod QR? Zeskanuj go aparatem telefonu, a kod wpisze się sam.</p>
    <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="join-nick" data-join disabled>Dalej</button></div>`, 'jt', 'dlg-join');
}
const NICKS = ['Kapitan Uszatek', 'Nova', 'Orbita', 'Meteor', 'Mat-7', 'Gwiazdka', 'Luna', 'Zebra z Kosmosu', 'Kosmo', 'Neptun', 'Rakietowy Seba'];
function nickErr(v, taken) {
  const t = (v || '').trim();
  if (!t) return 'Podaj pseudonim. Zobaczą go inni studenci w rankingu.';
  if (t.length < 2) return 'Pseudonim musi mieć co najmniej 2 znaki.';
  if (t.length > 24) return 'Pseudonim może mieć najwyżej 24 znaki.';
  if ((taken || NICKS).some(n => n.toLowerCase() === t.toLowerCase())) return 'Ten pseudonim jest już zajęty w tej grupie. Wybierz inny.';
  return null;
}
function dlgJoinNick() {
  const M = G.layerData;
  return cdlg(`<p class="small" style="margin-bottom:4px">Krok 2 z 2</p><h2 class="h2" id="jn">Dołączasz do grupy Zakon Algorytmów</h2>
    <p>W tej grupie inni zobaczą Cię pod pseudonimem — także w rankingu. Możesz go później zmienić w ustawieniach w grupie.</p>
    <div class="fld"><label for="f-jn">Pseudonim w tej grupie</label><div class="inp${M.err ? ' bad' : ''}"><input id="f-jn" data-nick="join" value="${esc(M.v || '')}" maxlength="24" data-focus></div>
      ${M.err ? `<p class="err" id="e-jn">${icon('alert')}${esc(M.err)}</p>` : '<span class="hint">Od 2 do 24 znaków. Musi być inny niż pseudonimy pozostałych osób w grupie.</span>'}</div>
    <div class="dlg-b"><button class="btn sec" data-act="close">Anuluj</button><button class="btn" data-act="join-go">Dołącz do grupy</button></div>`, 'jn', 'dlg-join');
}
function dlgJoined() {
  const g = DB.joinedNow || {name: 'Zakon Algorytmów', teacher: 'Janusz Nowakowski'};
  return cdlg(`<div class="oct art-img joined-art" style="background-image:${ART.waves}"></div><h2 class="h2" id="jd">Dołączono do grupy ${esc(g.name)}</h2>
    <p>Prowadzi ${esc(g.teacher)}. Jesteś tam jako <b>${esc(g.nick || '')}</b>. Walutą w tej grupie są Klejnoty.</p>
    <div class="dlg-b"><button class="btn" data-act="close" data-focus>Gotowe</button></div>`, 'jd');
}
function renderLayer() {
  const L = app.querySelector('#layer'); if (!L) return;
  if (!G.layer) { const m = curMod(); if (m && m.layer) m.layer(); else { L.innerHTML = ''; L.classList.remove('on'); } return; }
  const k = G.layer;
  L.innerHTML = k === 'notif' ? pop(popNotif()) : k === 'avatar' ? pop(popAvatar())
    : k === 'switch' ? pop(popSwitch(), isMobile() ? '' : 'pop-left')
    : k === 'more' ? ovl(sheetMore()) : k === 'join' ? ovl(dlgJoin())
    : k === 'join-nick' ? ovl(dlgJoinNick()) : k === 'joined' ? ovl(dlgJoined()) : '';
  L.classList.add('on');
  const f = L.querySelector('[data-focus]'); if (f) f.focus({preventScroll: true});
}
function openLayer(k, data) { const m = curMod(); if (m && m.closeLayer) m.closeLayer(); G.layerData = data || {}; G.layer = k; renderLayer(); }
function closeLayer() { G.layer = null; G.layerData = null; const m = curMod(); if (m && m.closeLayer) m.closeLayer(); renderLayer(); }

/* ---------- render ---------- */
function render(keep) {
  const r = ROUTE[G.route] || ROUTE['out/login'], m = MODS[r.mod];
  const mn = app.querySelector('.main'), top = keep && mn ? mn.scrollTop : 0;
  const bs = app.querySelector('.board-scroll'), bl = keep && bs ? [bs.scrollLeft, bs.scrollTop] : null;
  app.dataset.theme = G.theme;
  app.classList.toggle('in-group', r.chrome === 'group');
  const body = m ? m.page() : '<div class="page"><section class="panel"><p>Brak modułu.</p></section></div>';
  if (r.chrome === 'none') {
    app.innerHTML = body + `<div id="layer"></div><div class="toasts" id="toasts" aria-live="polite"></div>`;
  } else {
    const bg = (m && m.bg && m.bg()) || (r.bg === 'plain' ? '<div class="ttint plain"></div><div class="tpat"></div>'
      : `<div class="tbg" style="background-image:${ART.rabbits}"></div><div class="ttint"></div>`);
    app.innerHTML = header() + `<div class="body">${sidebar()}<div class="tw">${bg}<main class="main" id="main"${r.pad0 ? ' style="padding-bottom:0"' : ''}>${body}</main></div></div>${tabbar()}<div id="layer"></div><div class="toasts" id="toasts" aria-live="polite"></div>`;
  }
  const m2 = app.querySelector('.main'); if (m2) m2.scrollTop = top;
  const bs2 = app.querySelector('.board-scroll'); if (bs2 && bl) { bs2.scrollLeft = bl[0]; bs2.scrollTop = bl[1]; }
  renderLayer(); syncToolbar();
  if (m && m.after) m.after();
}
function setTheme(t) { G.theme = t; app.dataset.theme = t; syncToolbar(); }
function toast(html) {
  const t = app.querySelector('#toasts'); if (!t) return;
  const el = document.createElement('div'); el.className = 'toast'; el.setAttribute('role', 'status'); el.innerHTML = html;
  t.appendChild(el); setTimeout(() => el.remove(), 3400);
}
let hintT;
function hint(msg) {
  const h = document.getElementById('tb-hint'); if (!h) return;
  h.textContent = msg; h.classList.add('show'); clearTimeout(hintT); hintT = setTimeout(() => h.classList.remove('show'), 2800);
}

/* ---------- events ---------- */
const CORE_ACT = {
  noop() {},
  nav(a) { if (a.dataset.to) nav(a.dataset.to, {i: a.dataset.i, t: a.dataset.t, tab: a.dataset.tab}); else hint('No target route.'); },
  stub(a) { const g = a.dataset.g; hint('Only Kosmiczne króliki is wired in this mockup.'); toast(icon('lock') + `Grupa ${esc((GROUPS.find(x => x.id === g) || DB.myGroups.find(x => x.id === g) || {name: '—'}).name)} jest w makiecie tylko do podglądu.`); },
  hint() { hint('Not wired in this mockup.'); },
  theme() { setTheme(G.theme === 'dark' ? 'light' : 'dark'); render(true); },
  close: closeLayer,
  collapse() { G.collapsed = !G.collapsed; render(true); },
  bell() { openLayer('notif'); },
  avatar() { openLayer('avatar'); },
  switch() { openLayer('switch'); },
  more() { openLayer('more'); },
  join() { openLayer('join'); },
  'join-nick'() { const v = [...app.querySelectorAll('[data-slot]')].map(i => i.value).join(''); openLayer('join-nick', {code: v, v: ''}); },
  'join-go'() {
    const M = G.layerData, e = nickErr(M.v);
    if (e) { M.err = e; renderLayer(); return; }
    const g = DB.joinGroup(M.code, M.v.trim());
    openLayer('joined');
    toast(icon('check') + `Dołączono do grupy ${esc(g.name)} jako ${esc(g.nick)}.`);
  },
  readN(a) { DB.notes[+a.dataset.i].u = 0; closeLayer(); nav('t/purchases'); },
  readAll() { DB.notes.forEach(n => n.u = 0); render(true); openLayer('notif'); },
  logout() { G.layer = null; DB.pendingJoin = null; nav('out/login'); toast(icon('check') + 'Wylogowano.'); },
  settheme(a) { setTheme(a.dataset.t); render(true); },
  retry() { G.offline = false; nav(G.persona === 'teacher' ? 't/dash' : 's/home'); }
};
app.addEventListener('click', e => {
  const a = e.target.closest('[data-act]'); if (!a || !app.contains(a)) return;
  if (a.tagName === 'A') e.preventDefault();
  if (a.disabled) return;
  const k = a.dataset.act, m = curMod();
  const f = (m && m.act && m.act[k]) || CORE_ACT[k];
  if (f) f(a, e); else hint('No action: ' + k);
});
/* join-code inputs (core dialog) */
function checkJoin() { const ins = [...app.querySelectorAll('[data-slot]')], b = app.querySelector('[data-join]'); if (b) b.disabled = !ins.every(i => i.value); }
app.addEventListener('input', e => {
  const t = e.target;
  if (t.dataset.slot != null) {
    t.value = t.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(-1);
    if (t.value) { const n = app.querySelector(`[data-slot="${+t.dataset.slot + 1}"]`); if (n) n.focus(); }
    checkJoin();
  }
  if (t.dataset.nick === 'join' && G.layerData) {
    G.layerData.v = t.value;
    if (G.layerData.err) { G.layerData.err = null; t.parentNode.classList.remove('bad'); const m = app.querySelector('#e-jn'); if (m) m.remove(); }
  }
});
app.addEventListener('keydown', e => {
  const t = e.target; if (!t.dataset || t.dataset.slot == null) return;
  if (e.key === 'Backspace' && !t.value) { const p = app.querySelector(`[data-slot="${+t.dataset.slot - 1}"]`); if (p) { p.value = ''; p.focus(); e.preventDefault(); checkJoin(); } }
  if (e.key === 'Enter') { const b = app.querySelector('[data-join]'); if (b && !b.disabled) b.click(); }
});
app.addEventListener('paste', e => {
  const t = e.target; if (!t.dataset || t.dataset.slot == null) return;
  e.preventDefault();
  const txt = ((e.clipboardData || window.clipboardData).getData('text') || '').toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 6);
  const ins = [...app.querySelectorAll('[data-slot]')]; [...txt].forEach((c, k) => { if (ins[k]) ins[k].value = c; });
  ins[Math.min(txt.length, 5)].focus(); checkJoin();
});
document.addEventListener('keydown', e => { if (e.key === 'Escape' && G.layer) closeLayer(); });

/* module-scoped listeners: only fire while that module is on screen */
function on(modId, type, fn) { app.addEventListener(type, e => { if ((ROUTE[G.route] || {}).mod === modId) fn(e); }); }
function ondoc(modId, type, fn) { document.addEventListener(type, e => { if ((ROUTE[G.route] || {}).mod === modId) fn(e); }); }

/* ---------- frame + toolbar ---------- */
function layout() {
  const W = stage.clientWidth, H = stage.clientHeight; let dw, dh, s, x, y;
  if (G.frame === 'mobile') { dw = 390; dh = 844; s = Math.min(1, (H - 40) / dh, (W - 40) / dw); x = (W - dw * s) / 2; y = Math.max(20, (H - dh * s) / 2); }
  else { dw = Math.max(W, 1280); s = W / dw; dh = H / s; x = 0; y = 0; }
  stage.className = 'stage ' + G.frame;
  Object.assign(device.style, {width: dw + 'px', height: dh + 'px', transform: `translate(${x}px,${y}px) scale(${s})`});
  const sc = document.getElementById('tb-scale'); if (sc) sc.textContent = s < 0.995 ? `scaled to ${Math.round(s * 100)}%` : '';
}
function syncToolbar() {
  document.querySelectorAll('#tb-persona button').forEach(b => b.setAttribute('aria-pressed', b.dataset.p === G.persona));
  document.querySelectorAll('#tb-theme button').forEach(b => b.setAttribute('aria-pressed', b.dataset.t === G.theme));
  document.querySelectorAll('#tb-frame button').forEach(b => b.setAttribute('aria-pressed', b.dataset.f === G.frame));
  const sel = document.getElementById('tb-screen'); if (sel && sel.value !== G.route) sel.value = G.route;
}
function buildToolbar() {
  const sel = document.getElementById('tb-screen');
  const groups = {out: 'Logged out', s: 'Student', t: 'Teacher'};
  sel.innerHTML = Object.keys(groups).map(p => `<optgroup label="${groups[p]}">${Object.values(ROUTE).filter(r => r.persona === p).map(r => `<option value="${r.id}">${esc(r.label)}</option>`).join('')}</optgroup>`).join('');
  sel.addEventListener('change', () => nav(sel.value));
  document.getElementById('tb-persona').addEventListener('click', e => { const b = e.target.closest('button'); if (b) setPersona(b.dataset.p); });
  document.getElementById('tb-theme').addEventListener('click', e => { const b = e.target.closest('button'); if (b) { setTheme(b.dataset.t); render(true); } });
  document.getElementById('tb-frame').addEventListener('click', e => { const b = e.target.closest('button'); if (b) { G.frame = b.dataset.f; G.layer = null; layout(); render(false); } });
  document.getElementById('tb-reset').addEventListener('click', () => location.reload());
  document.getElementById('tb-offline').addEventListener('click', () => { G.offline = !G.offline; if (G.offline) nav('s/error'); else { G.offline = false; nav(G.persona === 'teacher' ? 't/dash' : 's/home'); } });
  window.addEventListener('resize', layout);
  window.addEventListener('hashchange', () => { const id = fromHash(); if (id && id !== G.route) nav(id); });
}
