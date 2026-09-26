import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class BadgeFlipController extends Controller<HTMLElement> {
  static targets = ["front", "back"]

  declare readonly frontTarget: HTMLElement
  declare readonly backTarget: HTMLElement

  toggle() {
    const down = this.element.classList.toggle("gh-flip-card--down")

    this.hide(this.frontTarget, down)
    this.hide(this.backTarget, !down)

    this.visibleFace(down).querySelector("button")?.focus()
  }

  private hide(face: HTMLElement, hidden: boolean) {
    face.inert = hidden

    if (hidden) face.setAttribute("aria-hidden", "true")
    else face.removeAttribute("aria-hidden")
  }

  private visibleFace(down: boolean): HTMLElement {
    return down ? this.backTarget : this.frontTarget
  }
}

application.register("badge-flip", BadgeFlipController)
