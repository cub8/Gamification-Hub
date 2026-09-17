import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The badge picker in "Przyznaj odznakę" (mockup 30-student.js:43-48).
 *
 * NEVER WRITES HTML. Every effect sentence is server-rendered, one per badge,
 * all hidden — this reveals the one that matches the selected radio. The
 * mockup rebuilds the whole dialog on every keystroke and then has to restore
 * focus and caret by hand (30-student.js:69-72); nothing here moves focus,
 * because nothing here is replaced.
 *
 * No Polish in this file. The submit label arrives as a value.
 */
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

    // At most one effect sentence is visible, and none until something is
    // chosen: a dialog that opens already explaining a badge nobody picked
    // reads as a mistake.
    this.effectTargets.forEach((effect) => {
      effect.hidden = effect.dataset.badgePickerFor !== chosen?.value
    })

    const label = chosen?.dataset.badgePickerLabel

    this.submitTarget.textContent = label ? `${this.pickValue} „${label}”` : this.blankValue
    this.submitTarget.disabled = !chosen
  }
}

/** Diacritics folded, so "zawsze" finds "Zawsze" and "lot" finds "Łot". */
function fold(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ł/g, "l")
}

application.register("badge-picker", BadgePickerController)
