import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The "Utwórz arkusz" dialog — mockup js-expanded/30-ag.js:57-65, 77-80.
 *
 * One form, two modes. Without this controller both halves are on screen and
 * the radio still decides which the server reads, so the dialog works either
 * way; what is added here is folding the half you are not using away, stepping
 * the count, and keeping the name chips and the submit label in step with it.
 *
 * Every name the stepper can reach is already in the markup — the server put
 * them there, from the same call that will name the records. Stepping only
 * changes how many are shown, so the preview cannot promise a name the save
 * does not use.
 */
class SheetCreateController extends Controller<HTMLElement> {
  static targets = [
    "mode", "onePane", "manyPane", "count", "output", "up", "down", "name", "submitLabel",
  ]

  static values = {
    sheets: Array,
    min: { type: Number, default: 2 },
  }

  declare readonly modeTargets: HTMLInputElement[]
  declare readonly onePaneTarget: HTMLElement
  declare readonly manyPaneTarget: HTMLElement
  declare readonly countTarget: HTMLInputElement
  declare readonly outputTarget: HTMLOutputElement
  declare readonly upTarget: HTMLButtonElement
  declare readonly downTarget: HTMLButtonElement
  declare readonly nameTargets: HTMLElement[]
  declare readonly submitLabelTarget: HTMLElement
  declare readonly sheetsValue: string[]
  declare readonly minValue: number

  connect() {
    this.refresh()
  }

  refresh() {
    const many = this.mode === "many"

    this.onePaneTarget.hidden = many
    this.manyPaneTarget.hidden = !many

    const count = this.count

    this.outputTarget.textContent = String(count)
    this.downTarget.disabled = count <= this.minValue
    this.upTarget.disabled = count >= this.max
    this.nameTargets.forEach((chip, index) => {
      chip.hidden = index >= count
    })

    this.submitLabelTarget.textContent = many
      ? `Utwórz ${count} ${plural(count, this.sheetsValue)}`
      : `Utwórz ${plural(1, this.sheetsValue)}`
  }

  up() {
    this.write(this.count + 1)
  }

  down() {
    this.write(this.count - 1)
  }

  private write(count: number) {
    this.countTarget.value = String(Math.min(this.max, Math.max(this.minValue, count)))
    this.refresh()
  }

  private get mode(): string {
    return this.modeTargets.find((radio) => radio.checked)?.value ?? "one"
  }

  private get count(): number {
    const parsed = Number.parseInt(this.countTarget.value, 10)

    if (!Number.isFinite(parsed)) return this.minValue

    return Math.min(this.max, Math.max(this.minValue, parsed))
  }

  /** However many names the server rendered is however far the stepper goes. */
  private get max(): number {
    return this.nameTargets.length
  }
}

function plural(count: number, forms: string[]): string {
  const [one, few, many] = forms
  const last = count % 10
  const teens = count % 100

  if (count === 1) return one
  if (last >= 2 && last <= 4 && (teens < 12 || teens > 14)) return few

  return many
}

application.register("sheet-create", SheetCreateController)
