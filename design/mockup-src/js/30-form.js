/* ===== module: form (new group wizard, from t/form.html) ===== */
(() => {
const ON = (t, f) => on('form', t, f), DON = (t, f) => ondoc('form', t, f);
/*BODY:form*/

delete ACT.theme;
ACT.hint = () => hint('Not wired in this mockup.');
ACT.finish = () => { nav('t/home'); toast(icon('check') + `Grupa „${esc(S.name)}” jest gotowa. Zaproszenia znajdziesz w zakładce Zaproszenia.`); };
ACT.reset = () => { Object.assign(S, fresh()); render(false); };

reg('form', {
  act: ACT,
  setView() { Object.assign(S, fresh()); },
  bg() { return S.art ? `<div class="tbg" style="${artStyle()}"></div><div class="ttint"></div>` : null; },
  page() {
    const body = S.done ? success()
      : `<div class="wiz${S.step > 1 ? ' full' : ''}"><section class="panel fcol" aria-labelledby="st-h"><h2 class="sr" id="st-h">${STEPS()[S.step]}</h2>${[step0, step1, step2, step3][S.step]()}</section>${S.step < 2 ? `<aside class="pcol" aria-label="Podgląd">${preview()}</aside>` : ''}</div>
        <div class="panel wbar">${S.step ? `<button class="btn sec" data-act="back">${icon('chevLeft')}Wstecz</button>` : `<button class="btn sec" data-act="nav" data-to="t/groups">${icon('chevLeft')}Anuluj</button>`}<span class="sp"></span><span class="k">Krok ${S.step + 1} z 4</span><button class="btn" data-act="next">${S.step === 3 ? (S.path === 'quick' ? 'Utwórz grupę z zestawem' : 'Utwórz pustą grupę') : 'Dalej'}${S.step < 3 ? icon('chevRight') : ''}</button></div>`;
    return `<div class="page">${S.done ? '' : `<section class="panel phead" style="display:block"><p class="crumbs"><a href="#/t/groups" data-act="nav" data-to="t/groups">Grupy</a>${icon('chevRight')}<span>Nowa grupa</span></p><h1>Nowa grupa</h1><p class="lead">Zajmie to kilka minut. Wszystko zmienisz później w ustawieniach grupy.</p>${stepper()}</section>`}${body}</div>`;
  }
});
})();
