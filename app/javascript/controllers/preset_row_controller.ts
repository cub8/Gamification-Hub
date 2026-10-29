import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { interpolate } from "@utils/i18n"

class PresetRowController extends Controller<HTMLElement> {
  static targets = ["keep", "label", "icon"]

  static values = { name: String, remove: String, restore: String }

  declare readonly keepTarget: HTMLInputElement
  declare readonly labelTarget: HTMLElement
  declare readonly iconTarget: HTMLElement
  declare readonly nameValue: string
  declare readonly removeValue: string
  declare readonly restoreValue: string

  connect() {
    this.render()
  }

  toggle() {
    this.render()
  }

  private render() {
    const kept = this.keepTarget.checked

    this.element.classList.toggle("gh-preset-row--removed", !kept)
    this.labelTarget.textContent = interpolate(kept ? this.removeValue : this.restoreValue, { name: this.nameValue })
    this.iconTarget.classList.toggle("fa-xmark", kept)
    this.iconTarget.classList.toggle("fa-rotate-left", !kept)

    this.element
      .querySelectorAll<HTMLInputElement>('input[type="number"]')
      .forEach((input) => {
        input.disabled = !kept
      })
  }
}

application.register("preset-row", PresetRowController)
