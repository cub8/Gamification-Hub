import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * A multiselect that looks like removable chips. Mockup: chips(),
 * js-expanded/30-item.js:25-26.
 *
 * The markup is a plain group of checkboxes, one per option, each wrapped in its
 * own chip label — so with this controller absent or broken the field is still a
 * working, fully visible, keyboard-operable checkbox group that posts the right
 * values. All this adds is the mockup's shape: unchosen chips step out of the
 * way and a "Dodaj…" select brings them back.
 *
 * Entity-agnostic on purpose — it never mentions badges, so the shop filters and
 * the sheet-template screens can reuse it.
 */
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
    // Leave the field the way the server rendered it, so a Turbo cache restore
    // never shows a half-hidden picker with no controller to un-hide it.
    this.chipTargets.forEach((chip) => (chip.hidden = false))
    if (this.hasAdderTarget) this.adderTarget.hidden = true
  }

  /** Chosen options are chips; unchosen ones live in the select. */
  sync() {
    this.chipTargets.forEach((chip) => {
      chip.hidden = !this.boxIn(chip)?.checked
    })

    this.optionTargets.forEach((option) => {
      const chosen = this.boxTargets.some((box) => box.value === option.value && box.checked)
      option.hidden = chosen
      // Hidden alone is not enough: some browsers still let the keyboard land
      // on a hidden <option>.
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
    // The checkbox is the control, so the change has to come from it — that is
    // what both this controller's own sync and the screen's controller are
    // listening to. Both events, because that is what a real click on the
    // checkbox would have produced.
    box.dispatchEvent(new Event("input", { bubbles: true }))
    box.dispatchEvent(new Event("change", { bubbles: true }))
  }

  private boxIn(chip: HTMLElement): HTMLInputElement | null {
    return chip.querySelector<HTMLInputElement>('input[type="checkbox"]')
  }
}

application.register("chip-picker", ChipPickerController)
