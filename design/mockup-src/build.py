#!/usr/bin/env python3
"""Concatenate the CSS and JS parts into one self-contained mockup HTML."""
import base64, json, pathlib, re, sys
sys.path.insert(0, str(pathlib.Path(__file__).parent / 'tools'))
import convert
from scope import scope_css

ROOT = pathlib.Path(__file__).parent
OUT = pathlib.Path('/mnt/user-data/outputs/gamification-hub-mockup.html')

b64 = lambda p: base64.b64encode(p.read_bytes()).decode()
RABBITS = 'data:image/jpeg;base64,' + b64(ROOT / 'assets/rabbits.jpg')

# per-module fixes applied to the converted template code
PATCHES = {
 'sp': [
  ('`<button class="btn sec" data-act="hint">${icon(\'bag\')}Przejd\u017a do sklepu</button>`',
   '`<button class="btn sec" data-act="go" data-to="s/shop">${icon(\'bag\')}Przejd\u017a do sklepu</button>`'),
  ('<p>Sta\u0107 ci\u0119 teraz na 4 przedmioty w sklepie.</p><button class="btn sec" data-act="hint">Zobacz sklep</button>',
   '<p>Sta\u0107 ci\u0119 teraz na ${(()=>{const n=shopItems().filter(it=>itemState(it).state===\'afford\').length;return n+\' \'+pl(n,\'przedmiot\',\'przedmioty\',\'przedmiot\u00f3w\');})()} w sklepie.</p><button class="btn sec" data-act="go" data-to="s/shop">Zobacz sklep</button>'),
  ("const rows=H.map(([a,t,x,w,c])=>{const r={a,t,x,w,c,after:run};run-=a;return r;})",
   "const rows=DB.me().hist.map(({amt:a,type:t,t:x,when:w,ctx:c})=>{const r={a,t,x,w,c,after:run};run-=a;return r;})"),
 ],
 'lists': [
  # data from the shared store
  ("const v=INV[S.inv||0],seed=", "const INV=activeInv();const v=INV[S.inv||0]||INV[0],seed="),
  ("const short=x=>(x.max?`u\u017cyto ${x.uses}/${x.max}`:'bez limitu')+', '+(x.exp?`do ${x.exp.split(',')[0]}`:'bezterminowo');",
   "const short=x=>(x.max?`u\u017cyto ${x.uses}/${x.max}`:'bez limitu')+', '+(x.exp?`do ${dmy(x.exp).split(',')[0]}`:'bezterminowo');"),
  ("const invTxt=v=>(v.max?`u\u017cyto ${v.uses} z ${v.max}`:`u\u017cyto ${v.uses} razy, bez limitu`)+', '+(v.exp?`wygasa ${v.exp}`:'bez daty wa\u017cno\u015bci');",
   "const invTxt=v=>(v.max?`u\u017cyto ${v.uses} z ${v.max}`:`u\u017cyto ${v.uses} razy, bez limitu`)+', '+(v.exp?`wygasa ${dmy(v.exp)}`:'bez daty wa\u017cno\u015bci');"),
  ("function vItems(){const it=ITEMS.slice().sort((a,b)=>a.cost-b.cost);",
   "function vItems(){const IT=shopItems(),it=IT.slice().sort((a,b)=>a.cost-b.cost);"),
  ("head('Przedmioty',`${ITEMS.length} ${pl(ITEMS.length,", "head('Przedmioty',`${IT.length} ${pl(IT.length,"),
  # wire the list actions to the forms
  ('`<button class="btn" data-act="hint">${icon(\'plus\')}Nowa ranga</button>`',
   '`<button class="btn" data-act="nav" data-to="t/rank-new">${icon(\'plus\')}Nowa ranga</button>`'),
  ('<button class="btn sec sm" data-act="hint">${icon(\'edit\')}Edytuj</button>',
   '<button class="btn sec sm" data-act="nav" data-to="t/rank-edit" data-i="${i}">${icon(\'edit\')}Edytuj</button>'),
  ('`<button class="btn" data-act="hint">${icon(\'plus\')}Nowa odznaka</button>`',
   '`<button class="btn" data-act="nav" data-to="t/badge-new">${icon(\'plus\')}Nowa odznaka</button>`'),
  ('<button class="btn sm" data-act="hint">Przyznaj</button><button class="iconbtn" data-act="hint" aria-label="Edytuj ${esc(b.name)}">${icon(\'edit\')}</button>',
   '<button class="btn sm" data-act="nav" data-to="t/students">Przyznaj</button><button class="iconbtn" data-act="nav" data-to="t/badge-edit" data-i="${b.id}" aria-label="Edytuj ${esc(b.name)}">${icon(\'edit\')}</button>'),
  ('`<button class="btn" data-act="hint">${icon(\'plus\')}Nowy przedmiot</button>`',
   '`<button class="btn" data-act="nav" data-to="t/item-new">${icon(\'plus\')}Nowy przedmiot</button>`'),
  ('<button class="iconbtn" data-act="hint" aria-label="Edytuj ${esc(x.name)}">${icon(\'edit\')}</button>',
   '<button class="iconbtn" data-act="nav" data-to="t/item-edit" data-i="${x.id}" aria-label="Edytuj ${esc(x.name)}">${icon(\'edit\')}</button>'),
  ('<button class="btn" data-act="hint">${icon(\'plus\')}Dodaj studenta</button>',
   '<button class="btn" data-act="nav" data-to="t/invites">${icon(\'plus\')}Zapro\u015b studenta</button>'),
  ('<button class="iconbtn" data-act="hint" aria-label="Przyznaj odznak\u0119: ${esc(s.name)}" title="Przyznaj odznak\u0119">${icon(\'badge\')}</button><button class="iconbtn" data-act="hint" aria-label="Koryguj walut\u0119: ${esc(s.name)}" title="Koryguj walut\u0119">${icon(\'coins\')}</button><button class="iconbtn" data-act="hint" aria-label="Historia: ${esc(s.name)}" title="Historia transakcji">${icon(\'history\')}</button>',
   '<button class="iconbtn" data-act="student" data-i="${i}" data-tab="assign" aria-label="Przyznaj odznak\u0119: ${esc(s.name)}" title="Przyznaj odznak\u0119">${icon(\'badge\')}</button><button class="iconbtn" data-act="student" data-i="${i}" data-tab="adjust" aria-label="Koryguj walut\u0119: ${esc(s.name)}" title="Koryguj walut\u0119">${icon(\'coins\')}</button><button class="iconbtn" data-act="student" data-i="${i}" data-tab="hist" aria-label="Historia: ${esc(s.name)}" title="Historia transakcji">${icon(\'history\')}</button>'),
  ('<button class="btn sec" data-act="hint">${icon(\'plus\')}Nowe zaproszenie</button>',
   '<button class="btn sec" data-act="nav" data-to="t/invites">${icon(\'plus\')}Zarz\u0105dzaj zaproszeniami</button>'),
 ],
 'student': [
  (" st:{name:'Sebastian Alejandro',email:'sebastian.alejandro@example.com',index:'s123456',bal:19,tot:34,lives:3,badges:['zawsze','agent'],items:[{id:'popr',when:'12.06, 10:21',paid:15}]},hist:H0};",
   " get st(){return DB.sel();},get hist(){return DB.sel().hist;}};"),
  ('<span class="av" data-h="0" aria-hidden="true">SA</span>', '${avatar(s.name)}'),
  ('<a href="#" data-act="hint">Studenci</a>', '<a href="#/t/students" data-act="nav" data-to="t/students">Studenci</a>'),
  ("nb=s.bal+d,nt=s.tot+d,", "nb=s.bal+d,nt=s.tot+Math.max(0,d),"),
  ("<dt>Zebrane \u0142\u0105cznie</dt><dd>${s.tot} \u2192 ${nt}</dd>", "<dt>Zebrane \u0142\u0105cznie</dt><dd>${s.tot}${nt!==s.tot?` \u2192 ${nt}`:' (bez zmian)'}</dd>"),
  ("<p class=\"small\" style=\"margin-top:8px\">Korekta zmienia te\u017c sum\u0119 zebranych, wi\u0119c mo\u017ce zmieni\u0107 rang\u0119.</p>",
   "<p class=\"small\" style=\"margin-top:8px\">${d>0?'Dodanie podnosi te\u017c sum\u0119 zebranych, wi\u0119c mo\u017ce podnie\u015b\u0107 rang\u0119.':'Odj\u0119cie zmniejsza tylko to, co student ma do wydania. Suma zebranych i ranga zostaj\u0105 bez zmian.'}</p>"),
  ("doAdjust(){const M=S.modal,d=M.sign*(+M.amt);S.st.bal+=d;S.st.tot+=d;S.hist.unshift({amt:d,type:'corr',t:M.why.trim()||'Korekta prowadz\u0105cego',when:'dzi\u015b, teraz',ctx:'John Curtin',fresh:1});S.modal=null;S.tab='hist';S.filter='all';render(true);toast(icon('coins')+`${d>0?'Dodano':'Odj\u0119to'} ${Math.abs(d)}. Saldo: ${S.st.bal}.`);}",
   "doAdjust(){const M=S.modal,d=DB.adjust(S.st,M.sign*(+M.amt),M.why.trim());S.modal=null;S.tab='hist';S.filter='all';render(true);toast(icon('coins')+`${d>0?'Dodano':'Odj\u0119to'} ${Math.abs(d)}. Saldo: ${S.st.bal}.`);}"),
 ],
 'rk': [
  ("visible:true,mode:'podium',",
   "get visible(){return DB.group.ranking;},set visible(v){DB.group.ranking=v;},get mode(){return DB.group.rankMode;},set mode(v){DB.group.rankMode=v;},"),
  (" teachers:[{name:'John Curtin',email:'john.curtin@example.com',owner:1,added:'01.06.2026'},{name:'Janusz Nowakowski',email:'janusz.nowakowski@example.com',added:'09.09.2026'}],",
   " get teachers(){return DB.teachers;},"),
 ],
 'isg': [
  (" inv:[{code:'M4TXW9',uses:12,max:15,exp:'2026-09-20T21:37'},{code:'K7RB2Q',uses:4,max:null,exp:null},{code:'P8HNZ3',uses:3,max:30,exp:'2026-09-30T12:00'},{code:'Z4QHR9',uses:3,max:3,exp:null},{code:'T2KWR7',uses:0,max:5,exp:'2026-09-01T12:00'}]};",
   " get inv(){return DB.invites;},set inv(v){DB.invites=v;}};"),
  ("<p class=\"lead\">Tylko w\u0142a\u015bciciel zmienia te ustawienia. Ranking ustawiasz w zak\u0142adce Ranking.</p>",
   "<p class=\"lead\">Zmieni\u0105 je wszyscy prowadz\u0105cy t\u0119 grup\u0119. Tylko w\u0142a\u015bciciel mo\u017ce usun\u0105\u0107 grup\u0119. Ranking ustawiasz w zak\u0142adce Ranking.</p>"),
  ('<button class="btn" data-act="hint">Otw\u00f3rz grup\u0119</button><button class="btn sec" data-act="hint">${icon(\'bag\')}Sklep</button>',
   '<button class="btn" data-act="openGroup" data-g="${g.id}" data-to="s/home">Otw\u00f3rz grup\u0119</button><button class="btn sec" data-act="openGroup" data-g="${g.id}" data-to="s/shop">${icon(\'bag\')}Sklep</button>'),
  ('<button class="btn sec" data-act="hint">${icon(\'plus\')}Do\u0142\u0105cz do grupy</button></div></div>',
   '<button class="btn sec" data-act="join">${icon(\'plus\')}Do\u0142\u0105cz do grupy</button></div></div>'),
 ],
 'gh': [
  ("const GS=[{name:'Kosmiczne kr\u00f3liki'", "const GS_T=[{id:'kk',name:'Kosmiczne kr\u00f3liki'"),
  ("const f=TABS.find(t=>t[0]===S.tab)[2],q=S.q.trim().toLowerCase(),list=GS.filter(f)",
   "const f=TABS.find(t=>t[0]===S.tab)[2],q=S.q.trim().toLowerCase(),list=GS().filter(f)"),
  ("<span class=\"n\">${GS.filter(fn).length}</span>", "<span class=\"n\">${GS().filter(fn).length}</span>"),
  ("<p class=\"lead\">Grupy, kt\u00f3re prowadzisz, wspierasz albo w kt\u00f3rych si\u0119 uczysz.</p></div><div class=\"rowb\"><button class=\"btn sec\" data-act=\"join\">${icon('plus')}Do\u0142\u0105cz do grupy</button><button class=\"btn\" data-act=\"hint\">${icon('plus')}Utw\u00f3rz grup\u0119</button></div>",
   "<p class=\"lead\">Grupy, kt\u00f3re prowadzisz, wspierasz albo w kt\u00f3rych si\u0119 uczysz.</p></div><div class=\"rowb\"><button class=\"btn sec\" data-act=\"join\">${icon('plus')}Do\u0142\u0105cz do grupy</button>${G.persona==='teacher'?`<button class=\"btn\" data-act=\"nav\" data-to=\"t/new-group\">${icon('plus')}Utw\u00f3rz grup\u0119</button>`:''}</div>"),
  ("<article class=\"card neutral ixc full\" data-act=\"hint\">", "<article class=\"card neutral ixc full\" data-act=\"openGroup\" data-g=\"${g.id||''}\">"),
  # teacher group home -> real destinations
  ("<button class=\"btn\" data-act=\"hint\">${icon('qr')}Poka\u017c kod dla student\u00f3w</button><button class=\"btn sec\" data-act=\"hint\">${icon('grid')}Utw\u00f3rz arkusz</button><button class=\"btn sec\" data-act=\"hint\">${icon('settings')}Ustawienia grupy</button>",
   "<button class=\"btn\" data-act=\"nav\" data-to=\"t/invites\">${icon('qr')}Poka\u017c kod dla student\u00f3w</button><button class=\"btn sec\" data-act=\"nav\" data-to=\"t/sheets\">${icon('grid')}Utw\u00f3rz arkusz</button><button class=\"btn sec\" data-act=\"nav\" data-to=\"t/group-settings\">${icon('settings')}Ustawienia grupy</button>"),
  ("<button class=\"linkbtn\" style=\"margin:10px 0 4px\" data-act=\"hint\">Wszystkie zakupy w grupie</button>",
   "<button class=\"linkbtn\" style=\"margin:10px 0 4px\" data-act=\"nav\" data-to=\"t/purchases\">Wszystkie zakupy w grupie</button>"),
  ("<b>Mateusz Lewandowski ma 0 \u017cy\u0107</b><small>Kupi tylko przedmioty dost\u0119pne przy 0 \u017cyciach.</small></span><button class=\"linkbtn\" data-act=\"hint\">Otw\u00f3rz</button>",
   "<b>Mateusz Lewandowski ma 0 \u017cy\u0107</b><small>Kupi tylko przedmioty dost\u0119pne przy 0 \u017cyciach.</small></span><button class=\"linkbtn\" data-act=\"nav\" data-to=\"t/student\" data-i=\"8\">Otw\u00f3rz</button>"),
  ("<b>Sebastian Alejandro: 6 do awansu</b><small>34 z 40 do rangi Kosmiczny Kr\u00f3lik.</small></span><button class=\"linkbtn\" data-act=\"hint\">Otw\u00f3rz</button>",
   "<b>${esc(DB.me().name)}: ${Math.max(0,40-DB.me().tot)} do awansu</b><small>${DB.me().tot} z 40 do rangi Kosmiczny Kr\u00f3lik.</small></span><button class=\"linkbtn\" data-act=\"nav\" data-to=\"t/student\" data-i=\"3\">Otw\u00f3rz</button>"),
  ("<button class=\"btn sm\" data-act=\"hint\">Oce\u0144</button>", "<button class=\"btn sm\" data-act=\"nav\" data-to=\"t/grade\">Oce\u0144</button>"),
  ("<b>${t}</b><button class=\"linkbtn\" data-act=\"hint\">Otw\u00f3rz</button>", "<b>${t}</b><button class=\"linkbtn\" data-act=\"nav\" data-to=\"t/sheets\">Otw\u00f3rz</button>"),
  # student group settings: live data + leave dialog wording
  ("nick:'Rakietowy Seba',nickIn:'Rakietowy Seba',nickErr:null}",
   "get nick(){return DB.me().nick;},set nick(v){DB.me().nick=v;},nickIn:DB.me().nick,nickErr:null}"),
  ("<p class=\"crumbs\"><a href=\"#\" data-act=\"hint\">Kosmiczne kr\u00f3liki</a>",
   "<p class=\"crumbs\"><a href=\"#/s/home\" data-act=\"nav\" data-to=\"s/home\">Kosmiczne kr\u00f3liki</a>"),
  ("<li><span>Imi\u0119 i nazwisko</span><b>Sebastian Alejandro</b></li><li><span>E-mail</span><b>sebastian.alejandro@example.com</b></li><li><span>Numer indeksu</span><b>s123456</b></li>",
   "<li><span>Imi\u0119 i nazwisko</span><b>${esc(DB.me().name)}</b></li><li><span>E-mail</span><b>${esc(DB.me().email)}</b></li><li><span>Numer indeksu</span><b>${esc(DB.me().index)}</b></li>"),
  ("<p>Stracisz dost\u0119p do sklepu, rankingu i swojej historii w tej grupie: 19 Z\u0142otych Marchewek, 2 odznak i 1 przedmiotu. Wr\u00f3ci\u0107 mo\u017cesz tylko z nowym kodem od prowadz\u0105cego.</p>",
   "<p>Stracisz dost\u0119p do sklepu, rankingu i swojej historii w tej grupie: ${DB.me().bal} ${curA(DB.me().bal)}, ${DB.me().badges.length} ${pl(DB.me().badges.length,'odznaki','odznak','odznak')} i ${DB.me().items.length} ${pl(DB.me().items.length,'przedmiotu','przedmiot\u00f3w','przedmiot\u00f3w')}.</p><p class=\"small\">Je\u015bli wr\u00f3cisz do tej grupy z nowym kodem od prowadz\u0105cego, wszystko wr\u00f3ci: waluta, odznaki i przedmioty. Nic nie przepada.</p>"),
 ],
 'ag': [
  # naming per DECISIONS: arkusze ocen / szablon arkusza / Utw\u00f3rz arkusz / Oce\u0144
  ("marchewek na studenta za zaj\u0119cia.", "marchewek na studenta za arkusz."),
  ("${icon('plus')}Utw\u00f3rz zaj\u0119cia</button>", "${icon('plus')}Utw\u00f3rz arkusz</button>"),
  ('<button class="btn sm${i===0?\'\':\' sec\'}" data-act="hint">Oce\u0144</button><button class="iconbtn" data-act="go" data-v="group" aria-label="Ustawienia: ${esc(g.name)}" title="Ustawienia zaj\u0119\u0107">',
   '<button class="btn sm${i===0?\'\':\' sec\'}" data-act="grade">Oce\u0144</button><button class="iconbtn" data-act="go" data-v="group" aria-label="Ustawienia: ${esc(g.name)}" title="Ustawienia arkusza">'),
  ("Z tego szablonu nie utworzono jeszcze zaj\u0119\u0107.", "Z tego szablonu nie utworzono jeszcze arkuszy."),
  ('<h1>Grupy aktywno\u015bci</h1><p class="lead">Zaj\u0119cia pogrupowane wed\u0142ug szablon\u00f3w. Najnowsze s\u0105 na g\u00f3rze.</p>',
   '<h1>Arkusze ocen</h1><p class="lead">Arkusze pogrupowane wed\u0142ug szablon\u00f3w. Najnowsze s\u0105 na g\u00f3rze.</p>'),
  ('${S.tpls.map(tplPanel).join(\'\')}<p class="more-l">Zarchiwizowane: 0</p>', '${S.tpls.map(tplPanel).join(\'\')}'),
  ("<span class=\"tag t-only\">Tylko w tych zaj\u0119ciach</span>", "<span class=\"tag t-only\">Tylko w tym arkuszu</span>"),
  ("<b>Zmiany dotycz\u0105 tylko zaj\u0119\u0107 utworzonych od teraz.</b> Laboratoria 1\u20135 zostaj\u0105 bez zmian.",
   "<b>Zmiany dotycz\u0105 tylko arkuszy utworzonych od teraz.</b> Laboratoria 1\u20135 zostaj\u0105 bez zmian."),
  ("<b>W tych zaj\u0119ciach przyznano ju\u017c 21 nagr\u00f3d.</b>", "<b>W tym arkuszu przyznano ju\u017c 21 nagr\u00f3d.</b>"),
  ("${grp?'Nazwa zaj\u0119\u0107':'Nazwa szablonu'}", "${grp?'Nazwa arkusza':'Nazwa szablonu'}"),
  ("Nowe zaj\u0119cia dostan\u0105 nazw\u0119 szablonu z kolejnym numerem, np. Laboratoria 6.",
   "Nowe arkusze dostan\u0105 nazw\u0119 szablonu z kolejnym numerem, np. Laboratoria 6."),
  # archiving -> soft delete
  ('<h2 class="h3">Archiwizacja</h2><p class="hint">${grp?\'Zaj\u0119cia znikn\u0105 z listy, a przyznane nagrody zostaj\u0105 u student\u00f3w.\':\'Szablon zniknie z listy, a utworzone z niego zaj\u0119cia zostaj\u0105.\'}</p><button class="btn sec" style="margin-top:12px" data-act="archive">${icon(\'archive\')}Archiwizuj ${grp?\'zaj\u0119cia\':\'szablon\'}</button>',
   '<h2 class="h3">Usuwanie</h2><p class="hint">${grp?\'Arkusz zniknie z listy, a przyznane nagrody zostaj\u0105 u student\u00f3w i w ich historii.\':\'Szablon zniknie z listy, a utworzone z niego arkusze zostaj\u0105.\'}</p><button class="btn sec" style="margin-top:12px" data-act="archive">${icon(\'trash\')}Usu\u0144 ${grp?\'arkusz\':\'szablon\'}</button>'),
  ("archive(){toast(icon('archive')+'Zarchiwizowano (makieta).');}",
   "archive(){const grp=S.view==='group';if(grp){const g=S.groups.find(x=>x.cur);if(g)g.del=1;}else{const t=TPL(JSON.parse(S.orig).id);if(t)t.del=1;}open('list');render(false);toast(icon('check')+(grp?'Usuni\u0119to arkusz Laboratoria 5. Przyznane nagrody zostaj\u0105 w historii student\u00f3w.':'Usuni\u0119to szablon. Utworzone z niego arkusze zostaj\u0105.'));}"),
  ("${S.tpls.map(tplPanel).join('')}", "${S.tpls.filter(x=>!x.del).map(tplPanel).join('')}"),
  ("function tplPanel(t){const gs=S.groups.filter(g=>g.tpl===t.id).slice().reverse();",
   "function tplPanel(t){const gs=S.groups.filter(g=>g.tpl===t.id&&!g.del).slice().reverse();"),
  ("Podaj nazw\u0119 zaj\u0119\u0107.", "Podaj nazw\u0119 arkusza."),
  ("'Zapisano szablon. Nowe zaj\u0119cia dostan\u0105 te kategorie.'", "'Zapisano szablon. Nowe arkusze dostan\u0105 te kategorie.'"),
  ("'Zapisano ustawienia zaj\u0119\u0107 Laboratoria 5.'", "'Zapisano ustawienia arkusza Laboratoria 5.'"),
  # "create sheets from template" modal
  ('<h2 class="h2" id="dt">Nowe zaj\u0119cia z szablonu ${esc(t.name)}</h2><p>Ka\u017cde zaj\u0119cia dostan\u0105 ${t.cats.length} ${pl(t.cats.length,\'kategori\u0119\',\'kategorie\',\'kategorii\')} z szablonu. Kolumny zmienisz p\u00f3\u017aniej w ustawieniach zaj\u0119\u0107.</p>',
   '<h2 class="h2" id="dt">Nowy arkusz z szablonu ${esc(t.name)}</h2><p>Ka\u017cdy arkusz dostanie ${t.cats.length} ${pl(t.cats.length,\'kategori\u0119\',\'kategorie\',\'kategorii\')} z szablonu. Kolumny zmienisz p\u00f3\u017aniej w ustawieniach arkusza.</p>'),
  ('aria-label="Ile zaj\u0119\u0107"><button data-act="mmode" data-v="one" aria-pressed="${M.mode===\'one\'}">Jedne zaj\u0119cia</button>',
   'aria-label="Ile arkuszy"><button data-act="mmode" data-v="one" aria-pressed="${M.mode===\'one\'}">Jeden arkusz</button>'),
  ('<p class="lbl" id="m-cnt">Ile zaj\u0119\u0107 utworzy\u0107</p>', '<p class="lbl" id="m-cnt">Ile arkuszy utworzy\u0107</p>'),
  ("${pl(M.mode==='one'?1:M.count,'grup\u0119 aktywno\u015bci','grupy aktywno\u015bci','grup aktywno\u015bci')}",
   "${pl(M.mode==='one'?1:M.count,'arkusz','arkusze','arkuszy')}"),
  ("marchewek za zaj\u0119cia.`;}", "marchewek za arkusz.`;}"),
 ],
 'item': [
  ('<div class="fsec"><h2 class="h3">Archiwizacja</h2><p class="hint">Przedmiot zniknie ze sklepu, ale studenci, kt\u00f3rzy go kupili, nadal go maj\u0105. Usun\u0105\u0107 mo\u017cna tylko przedmiot, kt\u00f3rego nikt nie kupi\u0142.</p><div class="rowb" style="margin-top:12px"><button class="btn sec" data-act="archive">${icon(\'archive\')}Archiwizuj przedmiot</button><button class="btn sec" disabled>Usu\u0144</button></div></div>',
   '<div class="fsec"><h2 class="h3">Usuwanie</h2><p class="hint">Przedmiot zniknie ze sklepu i z list. Studenci, kt\u00f3rzy go kupili, nadal go maj\u0105, a w ich historii zostanie jako „Usuni\u0119ty z oferty”.</p><div class="rowb" style="margin-top:12px"><button class="btn sec" data-act="archive">${icon(\'trash\')}Usu\u0144 przedmiot</button></div></div>'),
  ('<h2 class="h2" id="dt">Odrzuci\u0107 zmiany?</h2><p>Niezapisane zmiany w tym przedmiocie zostan\u0105 utracone.</p><div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Wr\u00f3\u0107 do edycji</button><button class="btn" data-act="discard">Odrzu\u0107 zmiany</button></div>',
   '${S.dlg===\'del\'?`<h2 class="h2" id="dt">Usun\u0105\u0107 „${esc(S.f.name)}” ze sklepu?</h2><p>Przedmiot zniknie ze sklepu i z list. Studenci, kt\u00f3rzy go kupili, zachowaj\u0105 go, a w historii zostanie oznaczony jako „Usuni\u0119ty z oferty”.</p><div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Anuluj</button><button class="btn" data-act="doDelete">Usu\u0144 z oferty</button></div>`:`<h2 class="h2" id="dt">Odrzuci\u0107 zmiany?</h2><p>Niezapisane zmiany w tym przedmiocie zostan\u0105 utracone.</p><div class="dlg-b"><button class="btn sec" data-act="close" data-focus>Wr\u00f3\u0107 do edycji</button><button class="btn" data-act="discard">Odrzu\u0107 zmiany</button></div>`}'),
 ],
 'br': [
  ('<div class="fsec"><h2 class="h3">Archiwizacja</h2><p class="hint">Odznaka zniknie z okna przyznawania, ale studenci, kt\u00f3rzy j\u0105 maj\u0105, zachowaj\u0105 j\u0105. Usun\u0105\u0107 mo\u017cna tylko odznak\u0119, kt\u00f3rej nikt nie ma.</p><div class="rowb" style="margin-top:12px"><button class="btn sec" data-act="archive">${icon(\'archive\')}Archiwizuj odznak\u0119</button><button class="btn sec" disabled>Usu\u0144</button></div></div>',
   '<div class="fsec"><h2 class="h3">Usuwanie</h2><p class="hint">Odznaka zniknie z listy i z okna przyznawania. Studenci, kt\u00f3rzy j\u0105 maj\u0105, zachowaj\u0105 j\u0105 w historii.</p><div class="rowb" style="margin-top:12px"><button class="btn sec" data-act="archive">${icon(\'trash\')}Usu\u0144 odznak\u0119</button></div></div>'),
  ("archive(){toast(icon('archive')+'Odznaka zarchiwizowana. Studenci j\u0105 zachowuj\u0105.');},del(){S.dlg='delete';layer();},dodel(){S.dlg=null;layer();toast(icon('check')+'Ranga usuni\u0119ta (makieta).');}",
   "noop2(){}"),
  ("${del?'Usun\u0105\u0107 rang\u0119 Pilot Marcheton-7?':'Odrzuci\u0107 zmiany?'}", "${del?(isB()?`Usun\u0105\u0107 odznak\u0119 „${esc(S.f.name)}”?`:`Usun\u0105\u0107 rang\u0119 ${esc(S.f.name)}?`):'Odrzuci\u0107 zmiany?'}"),
  ("${del?`<p>2 student\u00f3w spadnie do rangi Kosmiczny Kr\u00f3lik.</p>",
   "${del?`<p>${isB()?'Studenci, kt\u00f3rzy maj\u0105 t\u0119 odznak\u0119, zachowaj\u0105 j\u0105 w historii, ale nikt nowy jej nie dostanie.':'Studenci z t\u0105 rang\u0105 spadn\u0105 do ni\u017cszej.'}</p>"),
  ("${del?'Usu\u0144 rang\u0119':'Odrzu\u0107 zmiany'}", "${del?(isB()?'Usu\u0144 odznak\u0119':'Usu\u0144 rang\u0119'):'Odrzu\u0107 zmiany'}"),
 ],
 'form': [
  # DECISIONS: the success screen must not show the join code
  ('<p class="lbl" style="margin-top:22px">Kod dla student\u00f3w</p><div class="code-big" aria-label="Kod: K 7 R B 2 Q">K7RB2Q</div>\n <div class="rowb"><button class="btn sec" data-act="copy">${icon(\'copy\')}Kopiuj kod</button><button class="btn sec" data-act="hint">${icon(\'qr\')}Poka\u017c kod QR</button></div>',
   '<p class="expl" style="margin-top:22px">${icon(\'qr\')}<span>Kod do do\u0142\u0105czenia utworzysz w zak\u0142adce <b>Zaproszenia</b>, kiedy b\u0119dziesz go potrzebowa\u0107. Mo\u017cesz mie\u0107 kilka kod\u00f3w naraz, z limitem os\u00f3b albo dat\u0105 wa\u017cno\u015bci.</span></p>'),
  ('<button class="btn" data-act="hint">Przejd\u017a do grupy</button>',
   '<div class="rowb"><button class="btn" data-act="finish">Przejd\u017a do grupy</button><button class="btn sec" data-act="nav" data-to="t/invites">${icon(\'qr\')}Utw\u00f3rz zaproszenie</button></div>'),
  ("kategori\u0119','kategorie','kategorii')} zaj\u0119\u0107.", "kategori\u0119','kategorie','kategorii')} w szablonie arkusza."),
  ("'Po pierwszych zaj\u0119ciach utw\u00f3rz grup\u0119 aktywno\u015bci \u201eZaj\u0119cia 1\u201d i oce\u0144 student\u00f3w.'",
   "'Po pierwszych zaj\u0119ciach utw\u00f3rz arkusz ocen i oce\u0144 student\u00f3w.'"),
  ("'Utw\u00f3rz szablon kategorii zaj\u0119\u0107.'", "'Utw\u00f3rz szablon arkusza ocen.'"),
 ],
 'test': [
  ("document.getElementById('w').innerHTML=`", "return `"),
 ],
 'main': [
  ("const st = S.student, xs = ITEMS.map(it => ({it, ...itemState(it)}));",
   "const st = S.student, xs = shopItems().map(it => ({it, ...itemState(it)}));"),
  ("const afford = ITEMS.filter(it => itemState(it).state === 'afford').length;",
   "const afford = shopItems().filter(it => itemState(it).state === 'afford').length;"),
  ('data-act="nav" data-to="shop"', 'data-act="nav" data-to="s/shop"', 2),
  ('data-act="nav" data-to="grade">Oce\u0144 zaj\u0119cia', 'data-act="nav" data-to="t/grade">Oce\u0144'),
  ('data-act="nav" data-to="dash">Wr\u00f3\u0107 na start', 'data-act="nav" data-to="t/dash">Wr\u00f3\u0107 na start'),
  ('<button class="linkbtn" data-act="hint">Poka\u017c ca\u0142\u0105 histori\u0119</button>',
   '<button class="linkbtn" data-act="nav" data-to="s/history">Poka\u017c ca\u0142\u0105 histori\u0119</button>'),
  ('<a href="#" class="gt" data-act="hint">', '<a href="#" class="gt" data-act="${g.id === \'kk\' ? \'nav\' : \'stub\'}" data-to="t/home" data-g="${g.id}">'),
  ('<button class="btn sec" data-act="hint">${icon(\'plus\')}Utw\u00f3rz grup\u0119</button>',
   '<button class="btn sec" data-act="nav" data-to="t/new-group">${icon(\'plus\')}Utw\u00f3rz grup\u0119</button>'),
  ('<p class="crumbs"><a href="#" data-act="hint">Grupy aktywno\u015bci</a>${icon(\'chevRight\')}<a href="#" data-act="hint">Laboratoria</a></p>',
   '<p class="crumbs"><a href="#/t/sheets" data-act="nav" data-to="t/sheets">Arkusze ocen</a>${icon(\'chevRight\')}<a href="#/t/sheets" data-act="nav" data-to="t/sheets">Laboratoria</a></p>'),
  ("""  const st = S.student; st.balance -= x.price;
  st.items.unshift({id, when:'dzi\u015b, przed chwil\u0105'});
  S.ledger.unshift({amt:-x.price, type:'spend', t:it.name, when:'dzi\u015b, przed chwil\u0105'});
  S.purch.unshift({day:'Dzi\u015b', time:'teraz', stu:ME.s.name, item:id, g:'kk', price:x.price, fresh:true});
  S.notif++; S.layer = null; render(true);""",
   """  const st = S.student; if (!DB.buy(id)) return;
  closeLayer(); render(true);"""),
 ],
}



def module_body(mod):
    drop = DROP_EXTRA.get(mod, ())
    body = convert.convert(mod, drop)
    for rule in PATCHES.get(mod, []):
        a, b = rule[0], rule[1]
        want = rule[2] if len(rule) > 2 else 1
        n = body.count(a)
        if n != want:
            raise SystemExit(f'patch for {mod} matched {n}x (want {want}): {a[:70]}')
        body = body.replace(a, b)
    return body


DROP_EXTRA = {
    'sp': ('ME', 'H'),
    'lists': ('STUD', 'INV', 'ascii'),
    'student': ('H0',),
    'rk': ('STU', 'ME', 'GN'),
    'isg': ('MY',),
}


def build():
    parts = []
    for p in sorted((ROOT / 'src/css').glob('*.css')):
        text = p.read_text()
        if p.name.endswith('-test.css'):          # standalone dev page: keep it out of the app's cascade
            text = scope_css(text, '#w')
        parts.append(f'/* ---- {p.name} ---- */\n' + text)
    css = '\n'.join(parts)
    js_parts = []
    for p in sorted((ROOT / 'src/js').glob('*.js')):
        t = p.read_text()
        m = re.search(r'/\*BODY:(\w+)\*/', t)
        if m:
            t = t.replace(m.group(0), module_body(m.group(1)))
        js_parts.append(f'/* ---- {p.name} ---- */\n' + t)
    js = '\n'.join(js_parts)
    js = js.replace('__RABBITS__', RABBITS)
    if '__IMG_JSON__' in js:
        js = js.replace('__IMG_JSON__', (ROOT / 'assets/img.json').read_text().strip())
    html = (ROOT / 'src/index.html').read_text().replace('/*CSS*/', css).replace('/*JS*/', js)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(html)
    print('built', OUT, round(len(html) / 1024), 'KB')


if __name__ == '__main__':
    build()
