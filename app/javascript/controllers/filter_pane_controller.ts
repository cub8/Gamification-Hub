import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class FilterPaneController extends Controller<HTMLElement> {
  static targets = ["pane", "toggle", "count", "summary", "chips", "box"]
  static values = { removeLabel: String }

  declare readonly paneTarget: HTMLElement
  declare readonly toggleTarget: HTMLButtonElement
  declare readonly countTarget: HTMLElement
  declare readonly summaryTarget: HTMLElement
  declare readonly chipsTarget: HTMLElement
  declare readonly boxTargets: HTMLInputElement[]
  declare readonly removeLabelValue: string

  connect() {
    this.update()
  }

  toggle() {
    this.paneTarget.hidden = !this.paneTarget.hidden
    this.update()
  }

  clear() {
    this.boxTargets.filter((box) => box.checked).forEach((box) => this.untick(box))
  }

  update() {
    const ticked = this.boxTargets.filter((box) => box.checked)
    const open = !this.paneTarget.hidden

    this.toggleTarget.setAttribute("aria-expanded", String(open))
    this.countTarget.textContent = String(ticked.length)
    this.countTarget.hidden = ticked.length === 0

    this.summaryTarget.hidden = open || ticked.length === 0
    this.chipsTarget.replaceChildren(...ticked.map((box) => this.chipFor(box)))
  }

  private chipFor(box: HTMLInputElement): HTMLButtonElement {
    const text = `${box.dataset.group}: ${box.dataset.label}`
    const chip = document.createElement("button")
    const icon = document.createElement("i")

    chip.type = "button"
    chip.className = "gh-choice-chip gh-octagon-clip"
    chip.setAttribute("aria-label", `${this.removeLabelValue}: ${text}`)
    chip.append(text, " ")
    icon.className = "fa-solid fa-xmark"
    icon.setAttribute("aria-hidden", "true")
    chip.append(icon)
    chip.addEventListener("click", () => this.untick(box))

    return chip
  }

  private untick(box: HTMLInputElement) {
    box.checked = false
    box.dispatchEvent(new Event("change", { bubbles: true }))
  }
}

application.register("filter-pane", FilterPaneController)
