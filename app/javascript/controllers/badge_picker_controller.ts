import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class BadgePickerController extends Controller<HTMLFormElement> {
  static targets = ["input", "row", "radio", "effect", "empty", "submit"]
  static values = { pick: String, blank: String }

  declare readonly inputTarget: HTMLInputElement
  declare readonly rowTargets: HTMLElement[]
  declare readonly radioTargets: HTMLInputElement[]
  declare readonly effectTargets: HTMLElement[]
  declare readonly emptyTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly pickValue: string
  declare readonly blankValue: string

  connect() {
    this.pick()
  }

  filter() {
    const query = fold(this.inputTarget.value.trim())

    const shown = this.rowTargets.filter((row) => {
      const hit = fold(row.dataset.badgePickerName ?? "").includes(query)

      row.hidden = !hit

      return hit
    })

    this.emptyTarget.hidden = shown.length > 0
  }

  pick() {
    const chosen = this.radioTargets.find((radio) => radio.checked)

    this.effectTargets.forEach((effect) => {
      effect.hidden = effect.dataset.badgePickerFor !== chosen?.value
    })

    const label = chosen?.dataset.badgePickerLabel

    this.submitTarget.textContent = label ? `${this.pickValue} „${label}”` : this.blankValue
    this.submitTarget.disabled = !chosen
  }
}

function fold(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ł/g, "l")
}

application.register("badge-picker", BadgePickerController)
