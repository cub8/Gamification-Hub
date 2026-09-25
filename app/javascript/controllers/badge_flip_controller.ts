import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Turning a badge card over. Mockup: the flip is pure CSS there
 * (00-base.css:180-197) and its state is fixed — a student can never see the
 * other side.
 *
 * MOUNTED ON EARNED CARDS ONLY. An unearned badge stays face down because its
 * art is the reward; being able to peek would give that away. The deck decides
 * (badges/_student_deck.html.haml), so this controller never has to.
 *
 * The click listener is on the card, but the accessible control is the real
 * <button> inside each face: a click on it bubbles up to here, so Enter and
 * Space work natively and a screen reader gets a named control rather than an
 * <article> pretending to be a button.
 *
 * The turned-away face is `inert` as well as `aria-hidden`. `backface-
 * visibility` only hides it from the eye — without `inert` its button stays in
 * the tab order, which is the classic way a flip card traps a keyboard user on
 * a control they cannot see.
 */
class BadgeFlipController extends Controller<HTMLElement> {
  static targets = ["front", "back"]

  declare readonly frontTarget: HTMLElement
  declare readonly backTarget: HTMLElement

  toggle() {
    const down = this.element.classList.toggle("gh-flip-card--down")

    this.hide(this.frontTarget, down)
    this.hide(this.backTarget, !down)

    // Focus follows the card: the button you pressed is now on the far side.
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
