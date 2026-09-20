import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/** Index of the last step; step 4 in the copy, 3 here. */
const LAST_STEP = 3

/** The planned-classes stepper's bounds — Redesign::StarterPack::CLASSES_RANGE. */
const CLASSES_MIN = 4
const CLASSES_MAX = 30

/**
 * "Nowa grupa" — the four-step creation wizard (mockup js-expanded/30-form.js).
 *
 * The whole wizard is ONE form and nothing is written until the last submit, so
 * this controller only ever shows and hides what is already in the page. Two
 * consequences worth knowing:
 *
 *   * pressing Enter in a field on steps 1-3 would otherwise submit the whole
 *     form and create a half-configured group, so `keydown` swallows it and
 *     advances a step instead — the mockup's behaviour (30-form.js:113) and,
 *     here, a correctness fix rather than a nicety;
 *   * step 4's quick-start table is fetched from the server into a frame that
 *     lives INSIDE the form, which is what keeps the starter-pack arithmetic in
 *     Ruby while still letting its rows post with everything else.
 *
 * Previews clone whatever the checked picker tile shows, exactly as
 * rank_form_controller does, so there is nowhere for the two to disagree — and
 * it follows a crop, because image_crop_controller redraws that tile as you
 * drag and this listens for its `gh:image-crop`.
 */
class GroupWizardController extends Controller<HTMLElement> {
  static targets = [
    "form", "grid", "panel", "preview",
    "stepTab", "stepNum", "stepTick", "stepLabel",
    "name", "nameError", "currency", "currencyError",
    "ranking", "rankingMode",
    "path", "pathError", "pack", "quickOnly",
    "classes", "classesOutput", "classesUp", "classesDown",
    "manualSummary", "sumName", "sumCurrency", "sumLives", "sumRanking",
    "presetFrame",
    "previewGroup", "previewCurrency",
    "artBox", "artMono", "markBox", "markLetter",
    "nameEcho", "currencyEcho",
    "back", "cancel", "next", "nextLabel", "nextLabelShort", "nextIcon", "submit", "counter",
  ]

  static values = { presetUrl: String }

  declare readonly formTarget: HTMLFormElement
  declare readonly gridTarget: HTMLElement
  declare readonly panelTargets: HTMLElement[]
  declare readonly previewTarget: HTMLElement
  declare readonly stepTabTargets: HTMLButtonElement[]
  declare readonly stepNumTargets: HTMLElement[]
  declare readonly stepTickTargets: HTMLElement[]
  declare readonly stepLabelTargets: HTMLElement[]
  declare readonly nameTarget: HTMLInputElement
  declare readonly nameErrorTarget: HTMLElement
  declare readonly currencyTarget: HTMLInputElement
  declare readonly currencyErrorTarget: HTMLElement
  declare readonly rankingTarget: HTMLInputElement
  declare readonly rankingModeTarget: HTMLElement
  declare readonly pathTargets: HTMLInputElement[]
  declare readonly pathErrorTarget: HTMLElement
  declare readonly packTargets: HTMLInputElement[]
  declare readonly quickOnlyTargets: HTMLElement[]
  declare readonly classesTarget: HTMLInputElement
  declare readonly classesOutputTarget: HTMLOutputElement
  declare readonly classesUpTarget: HTMLButtonElement
  declare readonly classesDownTarget: HTMLButtonElement
  declare readonly manualSummaryTarget: HTMLElement
  declare readonly sumNameTarget: HTMLElement
  declare readonly sumCurrencyTarget: HTMLElement
  declare readonly sumLivesTarget: HTMLElement
  declare readonly sumRankingTarget: HTMLElement
  declare readonly presetFrameTarget: HTMLElement
  declare readonly previewGroupTarget: HTMLElement
  declare readonly previewCurrencyTarget: HTMLElement
  declare readonly artBoxTarget: HTMLElement
  declare readonly artMonoTarget: HTMLElement
  declare readonly markBoxTargets: HTMLElement[]
  declare readonly markLetterTargets: HTMLElement[]
  declare readonly nameEchoTarget: HTMLElement
  declare readonly currencyEchoTargets: HTMLElement[]
  declare readonly backTarget: HTMLElement
  declare readonly cancelTarget: HTMLElement
  declare readonly nextLabelTarget: HTMLElement
  declare readonly nextLabelShortTarget: HTMLElement
  declare readonly nextIconTarget: HTMLElement
  declare readonly submitTarget: HTMLInputElement
  declare readonly counterTarget: HTMLElement
  declare readonly presetUrlValue: string

  private step = 0

  /** High-water mark: visited steps stay clickable, later ones do not. */
  private max = 0

  /** What the last preset fetch asked for, so we do not refetch identically. */
  private fetched = ""

  connect() {
    // The server re-renders this page on a validation failure, so the step
    // carrying the error is where the teacher should land — not step 1.
    this.step = this.erroredStep
    this.max = this.step
    this.render()
  }

  // ---- navigation ----------------------------------------------------------

  goto(event: ActionEvent) {
    const index = Number(event.params.index)
    if (!Number.isInteger(index) || index > this.max) return

    this.step = index
    this.render()
    this.scrollToTop()
  }

  next() {
    if (!this.validate()) return

    if (this.step === LAST_STEP) {
      this.formTarget.requestSubmit(this.submitTarget)
      return
    }

    this.step += 1
    this.max = Math.max(this.max, this.step)
    this.render()
    this.scrollToTop()
  }

  back() {
    if (this.step === 0) return

    this.step -= 1
    this.render()
    this.scrollToTop()
  }

  /**
   * A step change is a page change, so it starts at the top. Step 1 is long
   * enough that "Dalej" sits well below the fold, and without this the next
   * step opens scrolled past its own heading.
   *
   * The scroller is #app-content (.gh-main is `overflow: auto`), NOT the
   * window — window.scrollTo is a no-op inside this shell. Called only from
   * the three navigation actions, never from render(), so a re-render for a
   * field edit leaves the scroll position alone; and never on connect(), so a
   * server-rendered error keeps the field it just focused in view.
   */
  private scrollToTop() {
    const scroller = this.element.closest("#app-content") ?? document.getElementById("app-content")

    scroller?.scrollTo({ top: 0, behavior: "smooth" })
  }

  /**
   * Enter must never reach the form itself before the last step. Textareas keep
   * it (a story is multi-line), and so does anything inside the preset frame,
   * where Enter in a number field should do nothing at all.
   */
  keydown(event: KeyboardEvent) {
    if (event.key !== "Enter") return

    const target = event.target as HTMLElement
    if (target instanceof HTMLTextAreaElement) return
    if (this.step === LAST_STEP) return

    event.preventDefault()
    this.next()
  }

  // ---- the planned-classes stepper ----------------------------------------

  classesUp() {
    this.writeClasses(this.classCount + 1)
  }

  classesDown() {
    this.writeClasses(this.classCount - 1)
  }

  private writeClasses(value: number) {
    this.classesTarget.value = String(Math.min(CLASSES_MAX, Math.max(CLASSES_MIN, value)))
    this.refresh()
  }

  private get classCount(): number {
    const parsed = Number.parseInt(this.classesTarget.value, 10)

    return Number.isFinite(parsed) ? parsed : CLASSES_MIN
  }

  // ---- reacting to the fields ---------------------------------------------

  refresh() {
    this.render()
  }

  /** The picker changed, or a crop was dragged. */
  art() {
    this.renderArt()
  }

  // ---- rendering -----------------------------------------------------------

  private render() {
    this.renderSteps()
    this.renderPanels()
    this.renderBar()
    this.renderArt()
    this.renderCurrency()
    this.renderStepThree()
    this.renderStepFour()
  }

  private renderSteps() {
    this.stepTabTargets.forEach((tab, index) => {
      const done = index < this.step

      tab.disabled = index > this.max
      tab.classList.toggle("gh-stp--on", index === this.step)
      tab.classList.toggle("gh-stp--ok", done)
      if (index === this.step) tab.setAttribute("aria-current", "step")
      else tab.removeAttribute("aria-current")

      this.stepNumTargets[index].hidden = done
      this.stepTickTargets[index].hidden = !done
    })

    // Only the last step's name depends on the chosen path.
    this.stepLabelTargets[LAST_STEP].textContent = this.quick ? "Przegląd zestawu" : "Podsumowanie"
  }

  private renderPanels() {
    this.panelTargets.forEach((panel, index) => {
      panel.hidden = index !== this.step
    })

    // The preview column is only meaningful while there is something to
    // preview; steps 3 and 4 take the full width, as `.wiz.full` does.
    const withPreview = this.step <= 1

    this.previewTarget.hidden = !withPreview
    this.gridTarget.classList.toggle("gh-wiz--full", !withPreview)
    this.previewGroupTarget.hidden = this.step !== 0
    this.previewCurrencyTarget.hidden = this.step !== 1
  }

  private renderBar() {
    this.counterTarget.textContent = `Krok ${this.step + 1} z ${LAST_STEP + 1}`
    this.backTarget.hidden = this.step === 0
    this.cancelTarget.hidden = this.step !== 0

    const last = this.step === LAST_STEP

    this.nextIconTarget.hidden = last
    this.nextLabelTarget.textContent = last ? this.createLabel : "Dalej"
    // The short label is what CSS shows below 720px, where the long one cannot
    // fit beside the back chevron. Both are written; the stylesheet chooses.
    this.nextLabelShortTarget.textContent = last ? "Utwórz grupę" : "Dalej"
  }

  private get createLabel(): string {
    return this.quick ? "Utwórz grupę z zestawem" : "Utwórz pustą grupę"
  }

  private renderArt() {
    this.nameEchoTarget.textContent = this.nameTarget.value.trim() || "Nazwa grupy"
    this.nameEchoTarget.classList.toggle("gh-ph", this.nameTarget.value.trim() === "")

    const art = this.chosen("[icon_glyph]")

    // Drop whatever was cloned last time, keeping the monogram node itself.
    this.artBoxTarget.querySelectorAll("[data-wizard-clone]").forEach((node) => node.remove())
    this.artBoxTarget.classList.toggle("gh-art--mono", art === null)
    this.artMonoTarget.hidden = art !== null
    this.artMonoTarget.textContent = monogram(this.nameTarget.value)

    if (art) this.artBoxTarget.prepend(mark(art))

    this.paintBackground(art)
  }

  /**
   * The group's artwork is also the table under the page, so picking a tile
   * changes the background behind the wizard itself — the mockup's `bg()`
   * (30-form.js:124) and its live `refresh()` (:95). Preset tiles and the
   * upload tile are both <img>, so one branch covers them.
   */
  private paintBackground(art: Element | null) {
    const layer = document.querySelector<HTMLElement>("[data-group-art-layer]")
    if (!layer) return

    const src = art instanceof HTMLImageElement ? art.currentSrc || art.src : ""

    layer.hidden = src === ""
    layer.style.backgroundImage = src === "" ? "" : `url(${CSS.escape(src)})`
  }

  private renderCurrency() {
    const name = this.currencyTarget.value.trim()

    this.currencyEchoTargets.forEach((echo) => {
      echo.textContent = name || "Marchewek"
      echo.classList.toggle("gh-ph", name === "")
    })

    // One chosen mark, several tokens showing it — the preview renders the
    // same coin at three sizes in each of the two themes.
    const glyph = this.chosen("[currency_icon_glyph]")
    const letter = (name[0] ?? "").toUpperCase()

    this.markBoxTargets.forEach((box) => {
      box.querySelectorAll("[data-wizard-clone]").forEach((node) => node.remove())
      if (glyph) box.prepend(mark(glyph))
    })

    this.markLetterTargets.forEach((slot) => {
      slot.hidden = glyph !== null
      slot.textContent = letter
    })

    this.rankingModeTarget.hidden = !this.rankingTarget.checked
  }

  private renderStepThree() {
    this.quickOnlyTargets.forEach((section) => {
      section.hidden = !this.quick
    })

    this.classesOutputTarget.textContent = String(this.classCount)
    this.classesDownTarget.disabled = this.classCount <= CLASSES_MIN
    this.classesUpTarget.disabled = this.classCount >= CLASSES_MAX
  }

  private renderStepFour() {
    const quick = this.quick

    this.manualSummaryTarget.hidden = quick
    this.presetFrameTarget.hidden = !quick

    // A frame left over from a switch to "Od zera" must not post its rows.
    // The server ignores them when the path is manual, but a disabled field is
    // the honest way to say the teacher is no longer choosing them.
    this.presetFrameTarget
      .querySelectorAll<HTMLInputElement>("input")
      .forEach((input) => {
        input.disabled = !quick
      })

    if (quick) this.loadPreset()
    else this.fillManualSummary()
  }

  /**
   * Fetched only once per (pack, classes, currency) combination, and only from
   * step 4 — the teacher may step back and forth over step 3 several times
   * before landing here.
   */
  private loadPreset() {
    if (this.step !== LAST_STEP) return

    const params = new URLSearchParams({
      pack: this.checked(this.packTargets) ?? "",
      classes: String(this.classCount),
      // Rails' own param name, so it stays snake_case.
      "currency_name": this.currencyTarget.value.trim(),
    })
    const url = `${this.presetUrlValue}?${params}`
    if (url === this.fetched) return

    this.fetched = url
    this.presetFrameTarget.setAttribute("src", url)
  }

  private fillManualSummary() {
    this.sumNameTarget.textContent = this.nameTarget.value.trim()
    this.sumCurrencyTarget.textContent = this.currencyTarget.value.trim()
    this.sumLivesTarget.textContent = this.livesField?.value ?? ""
    this.sumRankingTarget.textContent = this.rankingTarget.checked ?
      this.rankingLabel :
      "Wyłączony"
  }

  private get rankingLabel(): string {
    const select = this.rankingModeTarget.querySelector<HTMLSelectElement>("select")

    return select?.selectedOptions[0]?.textContent?.trim() ?? "Widoczny dla studentów"
  }

  private get livesField(): HTMLInputElement | null {
    return this.formTarget.querySelector<HTMLInputElement>('input[name$="[default_lives]"]')
  }

  // ---- validation ----------------------------------------------------------

  /**
   * Mirrors the model, not a second opinion of it: name and currency name are
   * both `presence` on StoryGroup, and the path is required because the last
   * step cannot be drawn without it. The server still decides — this only
   * stops the teacher reaching step 4 with a group that cannot be saved.
   */
  private validate(): boolean {
    const checks: [number, HTMLElement, boolean, HTMLElement | null][] = [
      [0, this.nameErrorTarget, this.nameTarget.value.trim() === "", this.nameTarget],
      [1, this.currencyErrorTarget, this.currencyTarget.value.trim() === "", this.currencyTarget],
      [2, this.pathErrorTarget, this.checked(this.pathTargets) === null, null],
    ]

    let ok = true

    for (const [step, slot, invalid, field] of checks) {
      if (step !== this.step) continue

      slot.hidden = !invalid
      field?.setAttribute("aria-invalid", String(invalid))
      field?.closest(".gh-inp")?.classList.toggle("gh-inp--bad", invalid)

      if (invalid) {
        ok = false
        ;(field ?? slot).focus?.()
      }
    }

    return ok
  }

  /** Which step the server's own errors belong to, so a reload lands there. */
  private get erroredStep(): number {
    if (this.nameTarget.getAttribute("aria-invalid") === "true") return 0
    if (this.currencyTarget.getAttribute("aria-invalid") === "true") return 1

    return 0
  }

  // ---- small helpers -------------------------------------------------------

  private get quick(): boolean {
    return this.checked(this.pathTargets) === "quick"
  }

  private checked(radios: HTMLInputElement[]): string | null {
    return radios.find((radio) => radio.checked)?.value ?? null
  }

  /**
   * The artwork inside the checked tile of one picker — an inline <svg>, or the
   * <img> for "Twoja grafika" and for every group-art preset. Same lookup
   * rank_form_controller makes.
   */
  private chosen(suffix: string): Element | null {
    const radio = this.element.querySelector<HTMLInputElement>(
      `input[type="radio"][name$="${suffix}"]:checked`,
    )

    return radio?.closest("label")?.querySelector("i")?.firstElementChild ?? null
  }
}

/** A clone tagged so the next render can find and drop it again. */
function mark(node: Element): Element {
  const copy = node.cloneNode(true) as Element

  copy.setAttribute("data-wizard-clone", "")

  return copy
}

/**
 * Two initials, skipping short words — "Wstęp do algorytmiki" reads "WA".
 * Mirrors RedesignHelper#gh_monogram, which draws the server-rendered cards.
 */
function monogram(name: string): string {
  const all = name.trim().split(/\s+/u).filter(Boolean)
  const words = all.filter((word) => word.length > 2)

  return (words.length ? words : all)
    .slice(0, 2)
    .map((word) => word[0].toUpperCase())
    .join("")
}

interface ActionEvent extends Event {
  params: { index?: number }
}

application.register("group-wizard", GroupWizardController)
