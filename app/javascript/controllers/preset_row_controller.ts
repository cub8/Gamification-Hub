import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * One row of the starter-pack review on step 4 of the creation wizard.
 *
 * The mockup keeps an exclusion set in JavaScript and re-renders the list
 * (30-form.js `ex`, :104). Here the state IS the posted value: a checked "keep"
 * box means the row becomes a record, and StarterPackBuilder reads it back by
 * index. So this controller only reflects that choice — it crosses the row out,
 * flips the icon between x and undo, and rewrites the screen-reader label.
 *
 * With JavaScript off the checkbox still works; the row simply does not go
 * grey, which costs nothing because the box itself says what it is.
 */
class PresetRowController extends Controller<HTMLElement> {
  static targets = ["keep", "label", "icon"]

  declare readonly keepTarget: HTMLInputElement
  declare readonly labelTarget: HTMLElement
  declare readonly iconTarget: HTMLElement

  /** The row's name, captured before the label is ever rewritten. */
  private name = ""

  connect() {
    this.name = this.labelTarget.textContent?.replace(/^\w+:\s*/u, "") ?? ""
    this.render()
  }

  toggle() {
    this.render()
  }

  private render() {
    const kept = this.keepTarget.checked

    this.element.classList.toggle("gh-preset-row--removed", !kept)
    this.labelTarget.textContent = `${kept ? "Usuń" : "Przywróć"}: ${this.name}`
    this.iconTarget.classList.toggle("fa-xmark", kept)
    this.iconTarget.classList.toggle("fa-rotate-left", !kept)

    // A removed row must not also fail validation on a number it no longer
    // contributes: `min` on an emptied field would block the whole submit.
    this.element
      .querySelectorAll<HTMLInputElement>('input[type="number"]')
      .forEach((input) => {
        input.disabled = !kept
      })
  }
}

application.register("preset-row", PresetRowController)
