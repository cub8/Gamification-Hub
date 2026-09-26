import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

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
