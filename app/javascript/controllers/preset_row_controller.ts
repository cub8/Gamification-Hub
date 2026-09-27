import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class PresetRowController extends Controller<HTMLElement> {
  static targets = ["keep", "label", "icon"]

  declare readonly keepTarget: HTMLInputElement
  declare readonly labelTarget: HTMLElement
  declare readonly iconTarget: HTMLElement

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

    this.element
      .querySelectorAll<HTMLInputElement>('input[type="number"]')
      .forEach((input) => {
        input.disabled = !kept
      })
  }
}

application.register("preset-row", PresetRowController)
