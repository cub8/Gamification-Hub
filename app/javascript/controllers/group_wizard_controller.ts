import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

const LAST_STEP = 3

const CLASSES_MIN = 4
const CLASSES_MAX = 30

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

  private max = 0

  private fetched = ""

  connect() {
    this.step = this.erroredStep
    this.max = this.step
    this.render()
  }

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

  private scrollToTop() {
    const scroller = this.element.closest("#app-content") ?? document.getElementById("app-content")

    scroller?.scrollTo({ top: 0, behavior: "smooth" })
  }

  keydown(event: KeyboardEvent) {
    if (event.key !== "Enter") return

    const target = event.target as HTMLElement
    if (target instanceof HTMLTextAreaElement) return
    if (this.step === LAST_STEP) return

    event.preventDefault()
    this.next()
  }

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

  refresh() {
    this.render()
  }

  art() {
    this.renderArt()
  }

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
      tab.classList.toggle("gh-wizard-step-tab--current", index === this.step)
      tab.classList.toggle("gh-wizard-step-tab--done", done)
      if (index === this.step) tab.setAttribute("aria-current", "step")
      else tab.removeAttribute("aria-current")

      this.stepNumTargets[index].hidden = done
      this.stepTickTargets[index].hidden = !done
    })

    this.stepLabelTargets[LAST_STEP].textContent = this.quick ? "Przegląd zestawu" : "Podsumowanie"
  }

  private renderPanels() {
    this.panelTargets.forEach((panel, index) => {
      panel.hidden = index !== this.step
    })

    const withPreview = this.step <= 1

    this.previewTarget.hidden = !withPreview
    this.gridTarget.classList.toggle("gh-form-shell--full", !withPreview)
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
    this.nextLabelShortTarget.textContent = last ? "Utwórz grupę" : "Dalej"
  }

  private get createLabel(): string {
    return this.quick ? "Utwórz grupę z zestawem" : "Utwórz pustą grupę"
  }

  private renderArt() {
    this.nameEchoTarget.textContent = this.nameTarget.value.trim() || "Nazwa grupy"
    this.nameEchoTarget.classList.toggle("gh-placeholder-text", this.nameTarget.value.trim() === "")

    const art = this.chosen("[icon_glyph]")

    this.artBoxTarget.querySelectorAll("[data-wizard-clone]").forEach((node) => node.remove())
    this.artBoxTarget.classList.toggle("gh-art--monogram", art === null)
    this.artMonoTarget.hidden = art !== null
    this.artMonoTarget.textContent = monogram(this.nameTarget.value)

    if (art) this.artBoxTarget.prepend(mark(art))

    this.paintBackground(art)
  }

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
      echo.classList.toggle("gh-placeholder-text", name === "")
    })

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

    this.presetFrameTarget
      .querySelectorAll<HTMLInputElement>("input")
      .forEach((input) => {
        input.disabled = !quick
      })

    if (quick) this.loadPreset()
    else this.fillManualSummary()
  }

  private loadPreset() {
    if (this.step !== LAST_STEP) return

    const params = new URLSearchParams({
      pack: this.checked(this.packTargets) ?? "",
      classes: String(this.classCount),
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
      field?.closest(".gh-text-input")?.classList.toggle("gh-text-input--invalid", invalid)

      if (invalid) {
        ok = false
        ;(field ?? slot).focus?.()
      }
    }

    return ok
  }

  private get erroredStep(): number {
    if (this.nameTarget.getAttribute("aria-invalid") === "true") return 0
    if (this.currencyTarget.getAttribute("aria-invalid") === "true") return 1

    return 0
  }

  private get quick(): boolean {
    return this.checked(this.pathTargets) === "quick"
  }

  private checked(radios: HTMLInputElement[]): string | null {
    return radios.find((radio) => radio.checked)?.value ?? null
  }

  private chosen(suffix: string): Element | null {
    const radio = this.element.querySelector<HTMLInputElement>(
      `input[type="radio"][name$="${suffix}"]:checked`,
    )

    return radio?.closest("label")?.querySelector("i")?.firstElementChild ?? null
  }
}

function mark(node: Element): Element {
  const copy = node.cloneNode(true) as Element

  copy.setAttribute("data-wizard-clone", "")

  return copy
}

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
