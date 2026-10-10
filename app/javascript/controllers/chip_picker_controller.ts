import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class ChipPickerController extends Controller<HTMLFieldSetElement> {
  static targets = ["chip", "box", "adder", "select", "option"]

  declare readonly chipTargets: HTMLLabelElement[]
  declare readonly boxTargets: HTMLInputElement[]
  declare readonly adderTarget: HTMLElement
  declare readonly hasAdderTarget: boolean
  declare readonly selectTarget: HTMLSelectElement
  declare readonly optionTargets: HTMLOptionElement[]

  connect() {
    this.sync()
  }

  disconnect() {
    this.chipTargets.forEach((chip) => (chip.hidden = false))
    if (this.hasAdderTarget) this.adderTarget.hidden = true
  }

  sync() {
    this.chipTargets.forEach((chip) => {
      chip.hidden = !this.boxIn(chip)?.checked
    })

    this.optionTargets.forEach((option) => {
      const chosen = this.boxTargets.some((box) => box.value === option.value && box.checked)
      option.hidden = chosen
      option.disabled = chosen
    })

    if (this.hasAdderTarget) {
      this.adderTarget.hidden = this.boxTargets.every((box) => box.checked)
    }
  }

  add(event: Event) {
    const select = event.currentTarget as HTMLSelectElement
    const box = this.boxTargets.find((candidate) => candidate.value === select.value)
    select.value = ""

    if (!box) return

    box.checked = true
    box.dispatchEvent(new Event("input", { bubbles: true }))
    box.dispatchEvent(new Event("change", { bubbles: true }))
  }

  private boxIn(chip: HTMLElement): HTMLInputElement | null {
    return chip.querySelector<HTMLInputElement>('input[type="checkbox"]')
  }
}

application.register("chip-picker", ChipPickerController)
