import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { pluralize, type PluralForms } from "@utils/i18n"

interface Wording {
  create_one: string
  create_many: PluralForms
}

class SheetCreateController extends Controller<HTMLElement> {
  static targets = [
    "mode", "onePane", "manyPane", "count", "output", "up", "down", "name", "submitLabel",
  ]

  static values = {
    i18n: Object,
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
  declare readonly i18nValue: Wording
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

    this.submitLabelTarget.textContent = many ? pluralize(this.i18nValue.create_many, count) : this.i18nValue.create_one
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

application.register("sheet-create", SheetCreateController)
