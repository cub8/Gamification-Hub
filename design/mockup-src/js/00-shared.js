const RABBITS = '__RABBITS__';
/* ===== shared helpers, icons, glyphs, data (from ct/app.js) ===== */
const esc = s => String(s).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pl = (n, one, few, many) => { n = Math.abs(n); if (n === 1) return one; const d = n % 10, h = n % 100; return (d >= 2 && d <= 4 && (h < 12 || h > 14)) ? few : many; };
const andList = a => a.length < 2 ? a.join('') : a.slice(0, -1).join(', ') + ' i ' + a[a.length - 1];

/* ---------------- Icons: 24px, square caps, mitred joins ---------------- */
const IC = {
  home:'<path d="M3 11l9-7 9 7v10h-6v-6H9v6H3z"/>',
  overview:'<path d="M3 3h8v8H3zM13 3h8v5h-8zM13 10h8v11h-8zM3 13h8v8H3z"/>',
  cards:'<path d="M8 3h12v15H8z"/><path d="M4 7v14h12"/>',
  bag:'<path d="M4 8h16l-1 13H5z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/>',
  chest:'<path d="M3 8h18v12H3z"/><path d="M3 13h18M10 11h4v4h-4zM7 8V4h10v4"/>',
  rank:'<path d="M5 12l7-6 7 6"/><path d="M5 19l7-6 7 6"/>',
  badge:'<path d="M7 3h10l3 5-8 8-8-8z"/><path d="M8 13l-2 8 6-3 6 3-2-8"/>',
  podium:'<path d="M9 7h6v14H9zM3 12h6v9H3zM15 10h6v11h-6z"/>',
  users:'<path d="M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"/><path d="M2 21v-2a5 5 0 0 1 5-5h4a5 5 0 0 1 5 5v2"/><path d="M16 3.5a4 4 0 0 1 0 7.5M22 21v-2a5 5 0 0 0-3-4.6"/>',
  grid:'<path d="M3 4h18v16H3zM3 10h18M3 15h18M9 4v16M15 4v16"/>',
  qr:'<path d="M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h3v3h-3zM18 18h3v3h-3zM14 20h2M20 14v2"/>',
  briefcase:'<path d="M3 7h18v13H3z"/><path d="M8 7V4h8v3M3 12h18"/>',
  bell:'<path d="M6 16v-6a6 6 0 0 1 12 0v6l2 2H4z"/><path d="M10 21h4"/>',
  sun:'<path d="M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10z"/><path d="M12 1v3M12 20v3M1 12h3M20 12h3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/>',
  moon:'<path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5z"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  lock:'<path d="M5 11h14v10H5z"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  check:'<path d="M5 12.5l4.5 4.5L19 7"/>',
  checks:'<path d="M2 12.5l4.5 4.5L15 7"/><path d="M13 16l1 1 8-9"/>',
  chevDown:'<path d="M6 9l6 6 6-6"/>',
  chevLeft:'<path d="M15 6l-6 6 6 6"/>',
  chevRight:'<path d="M9 6l6 6-6 6"/>',
  search:'<path d="M10.5 4a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13z"/><path d="M15.5 15.5L21 21"/>',
  heart:'<path d="M12 20.5S3.5 15.3 3.5 9A4.5 4.5 0 0 1 12 6.6 4.5 4.5 0 0 1 20.5 9c0 6.3-8.5 11.5-8.5 11.5z"/>',
  switch:'<path d="M4 8h15l-3-3M20 16H5l3 3"/>',
  logout:'<path d="M10 4H4v16h6M15 8l4 4-4 4M9 12h10"/>',
  settings:'<path d="M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2.1 2.1M16.9 16.9L19 19M5 19l2.1-2.1M16.9 7.1L19 5"/>',
  camera:'<path d="M3 7h4l2-3h6l2 3h4v13H3z"/><path d="M12 10a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7z"/>',
  more:'<path class="fill" d="M4 11h3v3H4zM10.5 11h3v3h-3zM17 11h3v3h-3z"/>',
  trash:'<path d="M5 7h14l-1 14H6z"/><path d="M9 7V4h6v3M3 7h18M10 11v6M14 11v6"/>',
  eyeOff:'<path d="M3 3l18 18"/><path d="M10.6 6.2A9 9 0 0 1 12 6c6 0 9 6 9 6a15 15 0 0 1-3.2 4M6.5 7.6A15 15 0 0 0 3 12s3 6 9 6a9 9 0 0 0 3.9-.9"/>',
  up:'<path d="M12 19V6M6 12l6-6 6 6"/>',
  desktop:'<path d="M3 4h18v12H3zM8 20h8M12 16v4"/>'
};
const fs = d => `<path class="f" d="${d}"/><path d="${d}"/>`;

/* ---------------- Preset card art (64px glyphs) ---------------- */
const P = 'M18 8h20l10 10v38H18z';
const CARROT = 'M42 22L10 56l36-28z';
const GL = {
  paperCheck: fs(P) + '<path d="M38 8v10h10M25 37l6 6 11-13"/>',
  retake: fs(P) + '<path d="M38 8v10h10"/><path d="M40.5 38.5a8 8 0 1 1-2.4-6.3"/><path d="M39 26v7h-7"/>',
  hourglass: '<path d="M16 6h32M16 58h32"/><path class="f" d="M24 58l8-9 8 9z"/><path d="M21 6c0 14 22 16 22 26S21 44 21 58M43 6c0 14-22 16-22 26s22 12 22 26"/>',
  chat: fs('M6 10h36v24H24l-9 9v-9H6z') + '<path d="M46 20h12v22h-7v9l-9-9H30v-4"/>',
  shield: fs('M32 5l21 7v16c0 13-8 23-21 30-13-7-21-17-21-30V12z') + '<path d="M23 31l7 7 12-13"/>',
  percent: '<path d="M14 52L50 12"/>' + fs('M12 12h13v13H12zM39 39h13v13H39z'),
  heartPlus: fs('M32 56S6 41 6 23a13 13 0 0 1 26-4 13 13 0 0 1 26 4c0 18-26 33-26 33z') + '<path d="M32 24v17M23.5 32.5h17"/>',
  note: fs('M6 14h52v36H6z') + '<path d="M6 14l26 20 26-20"/>',
  clock: fs('M24 6h16l14 14v16L40 50H24L10 36V20z') + '<path d="M32 16v13l9 6M20 58h24"/>',
  papers3: fs('M8 20h26v38H8z') + '<path d="M17 20v-7h26v38h-9M26 13V6h26v38h-9"/>',
  papers3shield: fs('M8 20h26v38H8z') + '<path d="M17 20v-7h26v14M26 13V6h26v20"/>' + fs('M46 30l12 4v8c0 8-5 13-12 17-7-4-12-9-12-17v-8z'),
  starPlus: fs('M28 10l7 14.5 16 2.3-11.6 11.3 2.7 16L28 46.6l-14.1 7.5 2.7-16L5 26.8l16-2.3z') + '<path d="M52 4v14M45 11h14"/>',
  flask: '<path class="f" d="M18 42h28l6 12H12z"/><path d="M24 8h16M27 8v16L12 54h40L37 24V8M18 42h28"/>',
  rabbit: '<path d="M24 30V6l7 5v19M40 30V6l-7 5v19"/>' + fs('M16 30h32v15l-8 11H24l-8-11z') + '<path d="M25 40h3M36 40h3M30 47h4"/>',
  rocket: fs('M32 4c10 8 13 20 11 32H21C19 24 22 12 32 4z') + '<path d="M21 34l-9 9v10l11-7M43 34l9 9v10l-11-7M27 42h10v12H27zM32 15v9"/>',
  carrot: fs(CARROT) + '<path d="M42 22l3-14M44 24l14-4M45 20l9-10M25 39l5 3M18 47l5 3"/>',
  compass: fs('M23 8h18l15 15v18L41 56H23L8 41V23z') + '<path d="M32 16l7 16-7 16-7-16zM25 32h14"/>',
  starTrail: fs('M42 8l5 10.2 11.2 1.6-8.1 7.9 1.9 11.2L42 33.6l-10 5.3 1.9-11.2-8.1-7.9L37 18.2z') + '<path d="M6 46h22M12 54h26M18 38h8"/>',
  wrench: fs('M44 6a13 13 0 0 0-12.5 17L8 46.5l9.5 9.5L41 32.5A13 13 0 0 0 58 20l-7.5 4.5-7-7L48 10z'),
  bolt: fs('M38 4L14 36h16l-5 24 25-34H34z'),
  crew: fs('M26 8h12v12H26zM8 16h10v10H8zM46 16h10v10H46zM22 28h20v26H22z') + '<path d="M4 54V32h14M60 54V32H46"/>',
  chev1: fs('M8 46l24-17 24 17v-10L32 19 8 36z'),
  chev2: fs('M8 36l24-17 24 17V26L32 9 8 26zM8 56l24-17 24 17V46L32 29 8 46z'),
  crown: fs('M8 46l4-30 12 13 8-19 8 19 12-13 4 30z') + '<path d="M8 55h48"/>',
  carrotStar: fs('M36 26L8 56l32-24z') + '<path d="M36 26l3-12M38 28l12-3M39 24l8-8"/>' + fs('M50 36l2.6 5.4 6 .9-4.3 4.2 1 6-5.3-2.8-5.3 2.8 1-6-4.3-4.2 6-.9z')
};
/* currency icons: in the real app this slot holds the teacher's uploaded icon */
const CI = {
  carrot: fs('M15.5 7.5L2.5 21.5l14.5-11z') + '<path d="M16 7.5l1-5.5M17 9l5.5-1.5M17.3 7.2L21.5 3"/>',
  pearl: fs('M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16z') + '<path d="M8.4 10.2a4 4 0 0 1 3.4-2.6"/>',
  bit: fs('M5 5h14v14H5z') + '<path d="M10 9.4l2.6-1.6v8.6"/>'
};
const LOGO = '<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M12 1h16l11 11v16L28 39H12L1 28V12z" style="fill:var(--item)"/><path d="M13.6 5h12.8L35 13.6v12.8L26.4 35H13.6L5 26.4V13.6z" style="fill:none;stroke:var(--on-item);stroke-width:1.6;opacity:.35"/><text x="20" y="25.4" text-anchor="middle" style="font:800 15px Bricolage Grotesque,sans-serif;fill:var(--on-item)">GH</text></svg>';
const MARK = '<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M12 1h16l11 11v16L28 39H12L1 28V12z" style="fill:var(--badge)"/><text x="20" y="25.4" text-anchor="middle" style="font:800 15px Bricolage Grotesque,sans-serif;fill:var(--card)">GH</text></svg>';

const svgUrl = s => `url('data:image/svg+xml;charset=utf-8,${encodeURIComponent(s)}')`;
const ART = {
  rabbits: `url('${RABBITS}')`,
  waves: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#0E4F5C"/><g fill="none" stroke-width="5"><path d="M-10 34q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#2F9DA3"/><path d="M-10 54q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#5CCFC6"/><path d="M-10 74q20-14 40 0t40 0 40 0 40 0 40 0" stroke="#2F9DA3"/></g><path d="M116 8h12l8 8v6h-28v-6z" fill="#F2C24E"/></svg>'),
  tables: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#35245E"/><g fill="none" stroke="#A58EE6" stroke-width="4"><path d="M18 18h50v54H18zM18 36h50M18 54h50M42 18v54"/><path d="M92 26h50v38H92zM92 44h50M116 26v38"/><path d="M68 45h24"/></g></svg>'),
  brackets: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#6B2E0E"/><g fill="none" stroke="#FFB27A" stroke-width="6"><path d="M54 22L30 45l24 23M106 22l24 23-24 23M90 16L70 74"/></g></svg>'),
  flow: svgUrl('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 90" preserveAspectRatio="xMidYMid slice"><rect width="160" height="90" fill="#17492F"/><g fill="none" stroke="#7CD6A0" stroke-width="4"><path d="M14 36h32v18H14zM114 36h32v18h-32z"/><path d="M80 22l16 23-16 23-16-23z"/><path d="M46 45h18M96 45h18"/></g></svg>')
};

/* ---------------- Data (real content from the current app) ---------------- */
const CUR = {
  carrot:{nom1:'Złota Marchewka',nom2:'Złote Marchewki',gen5:'Złotych Marchewek',acc1:'Złotą Marchewkę'},
  pearl:{nom1:'Perła',nom2:'Perły',gen5:'Pereł',acc1:'Perłę'},
  bit:{nom1:'Bit',nom2:'Bity',gen5:'Bitów',acc1:'Bit'}
};
const curN = (n, k = 'carrot') => pl(n, CUR[k].nom1, CUR[k].nom2, CUR[k].gen5);
const curA = (n, k = 'carrot') => pl(n, CUR[k].acc1, CUR[k].nom2, CUR[k].gen5);
const GROUPS = [
  {id:'kk',name:'Kosmiczne króliki',art:'rabbits',cur:'carrot',role:'owner',students:12,owner:'John Curtin',
   lore:'Galaktyka jest wielka, ale nasze uszy są większe! Dołącz do pionierów, którzy zamienili nory na stacje orbitalne. Walczymy o prestiż, przetrwanie i pełne brzuchy, zbierając Złote Marchewki w świecie, gdzie grawitacja to tylko sugestia. Pamiętaj: w kosmosie nikt nie usłyszy Twojego chrupania… chyba że zapomnisz wyłączyć interkom.'},
  {id:'atl',name:'Atlantyda',art:'waves',cur:'pearl',role:'support',students:18,owner:'Janusz Nowakowski'},
  {id:'alg',name:'Wstęp do algorytmiki szkolnej',art:'flow',cur:'bit',role:'owner',students:24,owner:'John Curtin'},
  {id:'rbd',name:'Relacyjne bazy danych',art:'tables',cur:'carrot',role:'owner',students:31,owner:'John Curtin'},
  {id:'io',name:'Inżynieria oprogramowania',art:'brackets',cur:'carrot',role:'owner',students:27,owner:'John Curtin'}
];
const GROUP = Object.fromEntries(GROUPS.map(g => [g.id, g]));
const RANKS = [
  {name:'Rekrut',min:0,disc:0,glyph:'chev1'},
  {name:'Kosmiczny Królik',min:40,disc:3,glyph:'chev2'},
  {name:'Pilot Marcheton-7',min:80,disc:5,glyph:'rocket'},
  {name:'Strateg Imperium',min:130,disc:10,glyph:'crown'},
  {name:'Mistrz Marchewki',min:190,disc:20,glyph:'carrotStar'}
];
const rankIdx = t => RANKS.reduce((a, r, i) => t >= r.min ? i : a, 0);
const BADGES = [
  {id:'dzielny',name:'Dzielny Królik',glyph:'rabbit',disc:2,flavor:'Królik nie uciekł z pola misji',rule:'Niezaliczona wejściówka, ale zdobyte co najmniej 4 marchewki łącznie w innych kategoriach'},
  {id:'zawsze',name:'Zawsze na pokładzie',glyph:'rocket',disc:3,flavor:'Rekrut nigdy nie opuścił statku',rule:'Co najmniej 26 marchewek za obecność'},
  {id:'zlota',name:'Złota Marchewka',glyph:'carrot',disc:2,flavor:'Idealna misja',rule:'Pierwszy raz wejściówka bez błędów'},
  {id:'strateg',name:'Strateg Floty',glyph:'compass',disc:3,flavor:'Dowództwo zauważyło skuteczność',rule:'Co najmniej 3 wejściówki z rzędu ≥ średnia grupy'},
  {id:'lot',name:'Perfekcyjny Lot',glyph:'starTrail',disc:5,flavor:'Lot bez najmniejszej rysy',rule:'Co najmniej 3 wejściówki z rzędu bez błędów'},
  {id:'mech',name:'Mechanik Załogi',glyph:'wrench',disc:2,flavor:'Królik naprawiał cudze statki',rule:'Zdobyte co najmniej 3 marchewki za pomoc innym'},
  {id:'agent',name:'Agent Chaosu',glyph:'bolt',disc:2,flavor:'Rekrut zrobił coś „po króliczemu”',rule:'Zdobyte co najmniej 3 marchewki za ciekawą uwagę'},
  {id:'druzyna',name:'Królik Drużynowy',glyph:'crew',disc:3,flavor:'Królik uratował załogę',rule:'Wyjaśnienie jakiegoś trudnego zagadnienia/zadania całej grupie'}
];
const BADGE = Object.fromEntries(BADGES.map(b => [b.id, b]));
const ITEMS = [
  {id:'bezp',name:'Bezpieczna poprawa',cost:20,glyph:'shield',flavor:'Statek trafia do hangaru ochronnego',rules:'Możliwość ponownego napisania (poprawy) wejściówki z zamrożeniem obecnego wyniku',discBadges:['zawsze','agent']},
  {id:'min5',name:'+5 minut do wejściówki',cost:15,glyph:'hourglass',flavor:'Spowolnienie czasu w nadprzestrzeni',rules:'Dodatkowe 5 minut na wejściówce'},
  {id:'kons',name:'Konsultacja',cost:15,glyph:'chat',flavor:'Konsultacja z Mistrzem Królików',rules:'Możliwość zadania prowadzącemu pytania podczas wejściówki (nie wprost o prawidłową odpowiedź)'},
  {id:'popr',name:'Poprawa wejściówki',cost:15,glyph:'retake',flavor:'Awaryjny powrót statku do bazy',rules:'Możliwość ponownego napisania (poprawy) wejściówki'},
  {id:'p5',name:'+5% do wejściówki',cost:30,glyph:'percent',flavor:'Flota dosyła dodatkowe zapasy',rules:'+5 punktów procentowych do wejściówki (do maksymalnie 100% w wyniku)'},
  {id:'p10',name:'+10% do wejściówki',cost:33,glyph:'percent',flavor:'Wsparcie dowództwa królików',rules:'+10 punktów procentowych do wejściówki (do maksymalnie 100% w wyniku)'},
  {id:'zal',name:'Zaliczenie wejściówki',cost:35,glyph:'paperCheck',flavor:'Statek wrócił z misji uszkodzony, ale wrócił',rules:'Zaliczenie słabo napisanej wejściówki na 50%',discBadges:['zawsze']},
  {id:'oneup',name:'1up',cost:50,glyph:'heartPlus',flavor:'Reanimacja królika',rules:'Odzyskanie jednego życia w ramach grywalizacji – kontynuacja gry',zeroLives:true},
  {id:'uspr',name:'Usprawiedliwienie',cost:10,glyph:'note',flavor:'Misja zdalna dla floty',rules:'Jedna usprawiedliwiona nieobecność bez straty marchewek za obecność i punktualność',req:{rank:1}},
  {id:'spoz',name:'Spóźnienie',cost:5,glyph:'clock',flavor:'Teleporter działał z opóźnieniem',rules:'Jedno spóźnienie bez straty marchewek za punktualność',req:{badges:['lot']}},
  {id:'pop3',name:'Poprawa trzech wejściówek',cost:40,glyph:'papers3',flavor:'W statku trzeba naprawić kilka modułów',rules:'Możliwość ponownego napisania (poprawy) trzech wybranych wejściówek',req:{badges:['mech']}},
  {id:'bez3',name:'Bezpieczna poprawa trzech wejściówek',cost:50,glyph:'papers3shield',flavor:'W statku trzeba naprawić kilka modułów i na ten czas królik otrzymuje statek zastępczy',rules:'Możliwość ponownego napisania (poprawy) trzech wybranych wejściówek z zamrożeniem obecnego wyniku',req:{rank:2,badges:['strateg']}},
  {id:'oc05',name:'0.5% oceny',cost:80,glyph:'starPlus',flavor:'Najwyższa Rada Królików przyznaje specjalną nagrodę za szczególne zasługi',rules:'Podniesienie oceny POZYTYWNEJ o pół stopnia',req:{rank:2}},
  {id:'oc3',name:'+3% do oceny',cost:80,glyph:'starPlus',flavor:'Wielka Marchewka dodaje królikowi punktów mocy',rules:'+3 punkty procentowe do ogólnego wyniku studenta/studentki',req:{rank:3}}
];
const ITEM = Object.fromEntries(ITEMS.map(i => [i.id, i]));
const CATS = [
  {name:'Punktualny/a',prize:2,flavor:'Rekrut stawił się na zbiórce floty króliczej i nie zgubił się w nadprzestrzeni.'},
  {name:'Obecny/a',prize:2,flavor:'Królik zameldował się na pokładzie.'},
  {name:'Wejściówka zaliczona',prize:1,flavor:'Misja zwiadowcza zakończona sukcesem.'},
  {name:'Wejściówka na poziomie co najmniej średniej grupy',prize:1,flavor:'Królik dotrzymał kroku całej flocie.'},
  {name:'Wejściówka na maxa',prize:2,flavor:'Lądowanie idealne, bez jednej rysy.'},
  {name:'Zgłoszenie się do zrobienia zadania',prize:1,flavor:'Ochotnik do misji specjalnej.'},
  {name:'Samodzielnie i poprawnie zrobione zadanie',prize:1,flavor:'Królik sam naprawił silnik.'},
  {name:'Pomoc innym',prize:1,flavor:'Holowanie uszkodzonego statku kolegi.'},
  {name:'Ciekawa uwaga',prize:1,flavor:'Sygnał z nieznanej galaktyki.'},
  {name:'Udział w dyskusji',prize:1,flavor:'Głos na naradzie dowództwa.'},
  {name:'Odpowiedź na pytanie wiedzy prowadzącego',prize:1,flavor:'Królik zna mapę gwiazd.'}
];
const STU = ['Adam Pawłowski','Barbara Kowalewska','Dawid Zebra','Sebastian Alejandro','Adrian Kowalski','Zofia Wiśniewska','Kacper Nowicki','Julia Wójcik','Mateusz Lewandowski','Natalia Kamińska','Oliwia Zielińska','Jakub Szymański'];
const ME = {s:{name:'Sebastian Alejandro',role:'student'}, t:{name:'John Curtin',role:'teacher'}};

const icon = (n, c = '') => `<svg class="ic ${c}" viewBox="0 0 24 24" aria-hidden="true">${IC[n] || ''}</svg>`;
const glyph = n => `<svg class="gph" viewBox="0 0 64 64" aria-hidden="true">${GL[n] || ''}</svg>`;
const cicon = (k = 'carrot') => `<svg class="cicon" viewBox="0 0 24 24" aria-hidden="true">${CI[k]}</svg>`;
const coin = (k = 'carrot', cls = '') => `<span class="coin ${cls}" aria-hidden="true">${cicon(k)}</span>`;
const initials = n => n.split(/\s+/).map(w => w[0]).slice(0, 2).join('').toUpperCase();
const hue = n => [...n].reduce((a, c) => a + c.charCodeAt(0), 0) % 5;
const avatar = (n, cls = '') => `<span class="av ${cls}" data-h="${hue(n)}" aria-hidden="true">${initials(n)}</span>`;
const bar = (v, max, label = '') => `<div class="bar" role="progressbar" aria-valuemin="0" aria-valuemax="${max}" aria-valuenow="${v}"${label ? ` aria-label="${esc(label)}"` : ''}><i style="--p:${Math.max(0, Math.min(100, Math.round(v / max * 100)))}%"></i></div>`;
const gthumb = (g, cls = '') => `<span class="gthumb ${cls}" style="background-image:${ART[g.art]}" aria-hidden="true"></span>`;
const gchip = g => `<span class="gchip">${gthumb(g)}<span>${esc(g.name)}</span></span>`;
const costChip = (price, orig, k = 'carrot', cls = '') => `<span class="cost ${cls}">${orig ? `<s>${orig}</s>` : ''}<b>${price}</b>${cicon(k)}</span>`;
const miniCard = (gl, cls = '') => `<span class="card item mc ${cls}"><span class="card-f"><span class="card-i">${glyph(gl)}</span></span></span>`;
const pItem = p => p.item ? ITEM[p.item] : {name:p.name, glyph:p.glyph};
const hearts = (n, max) => Array.from({length:max}, (_, i) => icon('heart', i < n ? 'hf' : 'he')).join('');