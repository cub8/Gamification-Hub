/* ===== DB: one canonical store shared by every screen =====
   Everything the modules used to keep in their own copies lives here, so that
   buying, awarding, joining, adjusting and assigning propagate across screens. */

const ascii = s => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/ł/g, 'l').replace(/Ł/g, 'L').toLowerCase().replace(/\s+/g, '.');

function mkStudent(name, bal, tot, lives, badges, nick, items, hist) {
  const s = {
    name, nick: nick || '', email: ascii(name) + '@example.com', index: 's' + (100000 + (name.length * 7919) % 800000),
    bal, tot, lives, badges: badges.slice(), items: (items || []).slice(), hist: (hist || []).slice()
  };
  Object.defineProperty(s, 'b', {get() { return this.badges; }, set(v) { this.badges = v; }});          // lists.html alias
  Object.defineProperty(s, 'balance', {get() { return this.bal; }, set(v) { this.bal = v; }});           // ct/app.js alias
  Object.defineProperty(s, 'total', {get() { return this.tot; }, set(v) { this.tot = v; }});
  return s;
}

const ME_HIST = [
  [-15, 'spend', 'Poprawa wejściówki', '12.06, 10:21', ''],
  [3, 'earn', 'Student zjawił się na zajęciach zdalnych', '12.06, 10:20', 'Laboratoria 4'],
  [3, 'earn', 'Student był obecny na wideorozmowie Teams', '12.06, 09:36', 'Laboratoria 4'],
  [4, 'earn', 'Wszystkie wejściówki bez błędów', '11.06, 18:43', 'Laboratoria 3'],
  [1, 'earn', 'Co najmniej jedna wejściówka bez błędów', '11.06, 18:43', 'Laboratoria 3'],
  [3, 'earn', 'Wszystkie wejściówki ≥ średnia grupy', '11.06, 18:42', 'Laboratoria 2'],
  [1, 'earn', 'Odpowiedź na pytanie wiedzy prowadzącego', '11.06, 18:41', 'Laboratoria 1'],
  [1, 'earn', 'Ciekawa uwaga', '11.06, 18:41', 'Laboratoria 1'],
  [1, 'earn', 'Wejściówka zaliczona', '11.06, 18:41', 'Laboratoria 1'],
  [2, 'earn', 'Obecny/a', '11.06, 18:41', 'Laboratoria 1'],
  [2, 'earn', 'Punktualny/a', '11.06, 18:41', 'Laboratoria 1']
].map(([amt, type, t, when, ctx]) => ({amt, type, t, when, ctx}));

const genHist = (name, tot) => [
  {amt: 2, type: 'earn', t: 'Punktualny/a', when: '11.06, 18:41', ctx: 'Laboratoria 1'},
  {amt: 2, type: 'earn', t: 'Obecny/a', when: '11.06, 18:41', ctx: 'Laboratoria 1'},
  {amt: Math.max(1, Math.round(tot / 6)), type: 'earn', t: 'Wejściówka zaliczona', when: '11.06, 18:41', ctx: 'Laboratoria 2'}
];

const DB = {
  /* --- people --- */
  students: [
    ['Adam Pawłowski', 60, 60, 12, ['zawsze', 'agent', 'zlota'], 'Kapitan Uszatek', [{id: 'oneup', when: '10.06, 12:30', paid: 50}]],
    ['Barbara Kowalewska', 26, 26, 3, ['zlota'], 'Luna', [{id: 'min5', when: '12.06, 09:58', paid: 15}]],
    ['Dawid Zebra', 23, 23, 3, [], 'Zebra z Kosmosu', []],
    ['Sebastian Alejandro', 19, 34, 3, ['zawsze', 'agent'], 'Rakietowy Seba', [{id: 'popr', when: '12.06, 10:21', paid: 15}], ME_HIST],
    ['Adrian Kowalski', 25, 25, 2, ['zlota'], '', [{id: 'kons', when: '11.06, 17:10', paid: 15}]],
    ['Zofia Wiśniewska', 35, 41, 3, ['zawsze', 'mech'], 'Meteor', []],
    ['Kacper Nowicki', 18, 18, 1, [], 'Kosmo', []],
    ['Julia Wójcik', 40, 52, 3, ['zawsze', 'mech', 'agent', 'zlota'], 'Nova', []],
    ['Mateusz Lewandowski', 22, 37, 0, [], 'Mat-7', []],
    ['Natalia Kamińska', 12, 12, 2, [], 'Neptun', []],
    ['Oliwia Zielińska', 29, 29, 3, ['zlota'], 'Gwiazdka', []],
    ['Jakub Szymański', 31, 44, 3, ['zawsze'], 'Orbita', []]
  ].map(([n, bal, tot, lives, b, nick, items, hist]) => mkStudent(n, bal, tot, lives, b, nick, items, hist || genHist(n, tot))),

  teacher: {name: 'John Curtin', email: 'john.curtin@example.com', role: 'teacher', uni: 'Politechnika Gdańska', usos: '162431', index: '—'},

  /* --- group-level state (Kosmiczne króliki, the one fully wired group) --- */
  group: {id: 'kk', name: 'Kosmiczne króliki', cur: 'carrot', lives: 3, ranking: true, rankMode: 'podium'},

  teachers: [
    {name: 'John Curtin', email: 'john.curtin@example.com', owner: 1, added: '01.06.2026'},
    {name: 'Janusz Nowakowski', email: 'janusz.nowakowski@example.com', added: '09.09.2026'}
  ],
  invites: [
    {code: 'K7RB2Q', uses: 8, max: null, exp: null},
    {code: 'M4XPZT', uses: 3, max: 30, exp: '2026-09-30T23:59'},
    {code: 'R9HTWD', uses: 12, max: 12, exp: null},
    {code: 'B3NKQS', uses: 2, max: null, exp: '2026-09-01T23:59'}
  ],

  /* --- shop / purchases / notifications --- */
  purch: [
    {day: 'Dziś', time: '10:21', stu: 'Sebastian Alejandro', item: 'popr', g: 'kk', price: 15},
    {day: 'Dziś', time: '09:58', stu: 'Barbara Kowalewska', item: 'min5', g: 'kk', price: 15},
    {day: 'Dziś', time: '08:40', stu: 'Dawid Zebra', name: 'Eliksir energetyczny', glyph: 'flask', g: 'atl', price: 12},
    {day: 'Wczoraj', time: '18:43', stu: 'Sebastian Alejandro', name: 'Zwolnienie z wejściówki', glyph: 'paperCheck', g: 'alg', price: 20},
    {day: 'Wczoraj', time: '17:10', stu: 'Adrian Kowalski', item: 'kons', g: 'kk', price: 15},
    {day: 'Wczoraj', time: '12:05', stu: 'Zofia Wiśniewska', name: 'Eliksir energetyczny', glyph: 'flask', g: 'atl', price: 12},
    {day: 'Wcześniej', time: '10.06', stu: 'Adam Pawłowski', item: 'oneup', g: 'kk', price: 50},
    {day: 'Wcześniej', time: '09.06', stu: 'Julia Wójcik', name: 'Zwolnienie z wejściówki', glyph: 'paperCheck', g: 'alg', price: 20}
  ],
  notes: [
    {u: 1, stu: 'Sebastian Alejandro', item: 'popr', g: 'kk', when: 'dziś, 10:21', price: 15},
    {u: 1, stu: 'Barbara Kowalewska', item: 'min5', g: 'kk', when: 'dziś, 09:58', price: 15},
    {u: 1, stu: 'Dawid Zebra', name: 'Eliksir energetyczny', glyph: 'flask', g: 'atl', when: 'dziś, 08:40', price: 12},
    {u: 0, stu: 'Sebastian Alejandro', name: 'Zwolnienie z wejściówki', glyph: 'paperCheck', g: 'alg', when: 'wczoraj, 18:43', price: 20},
    {u: 0, stu: 'Adrian Kowalski', item: 'kons', g: 'kk', when: 'wczoraj, 17:10', price: 15},
    {u: 0, stu: 'Zofia Wiśniewska', name: 'Eliksir energetyczny', glyph: 'flask', g: 'atl', when: 'wczoraj, 12:05', price: 12}
  ],

  /* --- student session --- */
  meIdx: 3,
  selIdx: 3,
  myGroups: [
    {id: 'kk', name: 'Kosmiczne króliki', art: 'rabbits', cur: 'carrot', teacher: 'John Curtin',
     c: ['Złota Marchewka', 'Złote Marchewki', 'Złotych Marchewek'],
     get bal() { return DB.me().bal; }, get tot() { return DB.me().tot; }, get lives() { return DB.me().lives; },
     get rank() { return RANKS[rankIdx(DB.me().tot)].name; },
     get next() { const i = rankIdx(DB.me().tot), n = RANKS[i + 1]; return n ? [n.name, n.min] : [RANKS[i].name, RANKS[i].min]; },
     get b() { return [DB.me().badges.length, BADGES.length]; },
     get nick() { return DB.me().nick; }, set nick(v) { DB.me().nick = v; }},
    {id: 'alg', name: 'Wstęp do algorytmiki szkolnej', art: 'flow', cur: 'bit', teacher: 'John Curtin', nick: 'Seb',
     c: ['Bit', 'Bity', 'Bitów'], bal: 7, tot: 23, rank: 'Uczeń', next: ['Adept', 25], lives: 2, b: [1, 6]},
    {id: 'rbd', name: 'Relacyjne bazy danych', art: 'tables', cur: 'pearl', teacher: 'John Curtin', nick: '',
     c: ['Perła', 'Perły', 'Pereł'], bal: 0, tot: 0, rank: 'Nowicjusz', next: ['Uczeń', 10], lives: 3, b: [0, 6], fresh: 1}
  ],
  pendingJoin: null,     // code remembered across login/registration (QR)
  joinedNow: null,

  /* --- grading --- */
  sheet: {name: 'Laboratoria 5'},
  grid: null,
  soldOut: {},           // soft-deleted items: id -> true
  seen: {}
};

DB.me = () => DB.students[DB.meIdx];
DB.sel = () => DB.students[DB.selIdx];
DB.byName = n => DB.students.find(s => s.name === n);
DB.unread = () => DB.notes.filter(n => n.u).length;

/* grading grid: 0 empty, 1 marked now, 2 awarded (locked) */
DB.grid = (() => {
  const g = DB.students.map(() => CATS.map(() => 0));
  DB.students.forEach((_, i) => { if (i !== 4 && i !== 9) g[i][0] = 2; if (i !== 9) g[i][1] = 2; });
  [0, 1, 2, 3, 5, 6, 8, 10].forEach(i => g[i][2] = 1);
  [0, 3, 6].forEach(i => g[i][3] = 1);
  [1, 5].forEach(i => g[i][9] = 1);
  [0, 2].forEach(i => g[i][10] = 1);
  return g;
})();

/* ---- mutations used by more than one screen ---- */
const NOWT = 'dziś, przed chwilą';

DB.buy = function (id) {
  const it = ITEM[id], x = itemState(it), me = DB.me();
  if (x.state !== 'afford') return null;
  me.bal -= x.price;
  me.items.unshift({id, when: NOWT, paid: x.price});
  me.hist.unshift({amt: -x.price, type: 'spend', t: it.name, when: NOWT, ctx: ''});
  DB.purch.unshift({day: 'Dziś', time: 'teraz', stu: me.name, item: id, g: 'kk', price: x.price, fresh: true});
  DB.notes.unshift({u: 1, stu: me.name, item: id, g: 'kk', when: NOWT, price: x.price});
  return x;
};

/* positive corrections raise the total collected (and therefore the rank),
   negative ones lower only the spendable balance and never below 0 */
DB.adjust = function (stu, delta, why) {
  if (delta < 0) delta = -Math.min(-delta, stu.bal);
  stu.bal += delta;
  if (delta > 0) stu.tot += delta;
  stu.hist.unshift({amt: delta, type: 'corr', t: why || 'Korekta prowadzącego', when: NOWT, ctx: DB.teacher.name, fresh: 1});
  return delta;
};

DB.awardCells = function () {
  const cells = [], per = new Map();
  DB.grid.forEach((r, i) => r.forEach((v, j) => {
    if (v === 1) {
      r[j] = 2; cells.push([i, j]);
      per.set(i, (per.get(i) || 0) + CATS[j].prize);
      const s = DB.students[i];
      s.hist.unshift({amt: CATS[j].prize, type: 'earn', t: CATS[j].name, when: NOWT, ctx: DB.sheet.name});
    }
  }));
  per.forEach((sum, i) => { DB.students[i].bal += sum; DB.students[i].tot += sum; });
  return {cells, students: per.size, sum: [...per.values()].reduce((a, b) => a + b, 0)};
};

DB.joinGroup = function (code, nick) {
  const g = {id: 'zak', name: 'Zakon Algorytmów', art: 'waves', cur: 'pearl', teacher: 'Janusz Nowakowski', nick: nick || '', fresh: 1,
    c: ['Klejnot', 'Klejnoty', 'Klejnotów'], bal: 0, tot: 0, lives: 3, rank: 'Nowicjusz', next: ['Uczeń', 10], b: [0, 8], code};
  if (!DB.myGroups.some(x => x.id === g.id)) DB.myGroups.unshift(g);
  DB.joinedNow = g; DB.pendingJoin = null;
  return g;
};
