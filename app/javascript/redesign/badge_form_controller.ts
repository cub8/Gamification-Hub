import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The live preview beside the badge form. Mockup: js-expanded/30-br.js:62-69.
 *
 * Like rank_form_controller it NEVER GENERATES MARKUP. Both faces of the card
 * and the award-row thumbnail are server-rendered, which is what lets the
 * glyphs stay inline SVG; this only rewrites their text and clones the picked
 * artwork. With JavaScript off the preview is still correct, just static, and
 * there is no second copy of the card markup to drift.
 *
 * The rule appears on BOTH faces — as the card's rules line and as the "Jak
 * zdobyć" text on the back — so one keystroke has to land in two places. That
 * is the whole reason this controller is not just `refresh()` on the front.
 */
class BadgeFormController extends Controller<HTMLFormElement> {
  static targets = [
    "name", "rule", "story", "discount",
    "frontName", "frontArt", "frontRules", "frontFlavor", "frontTag",
    "backName", "backHow",
    "thumbArt", "thumbName", "thumbSub",
    "flip", "side",
  ]

  declare readonly nameTarget: HTMLInputElement
  declare readonly ruleTarget: HTMLTextAreaElement
  declare readonly storyTarget: HTMLTextAreaElement
  declare readonly discountTarget: HTMLInputElement
  declare readonly frontNameTarget: HTMLElement
  declare readonly frontArtTarget: HTMLElement
  declare readonly frontRulesTarget: HTMLElement
  declare readonly frontFlavorTarget: HTMLElement
  declare readonly frontTagTarget: HTMLElement
  declare readonly backNameTarget: HTMLElement
  declare readonly backHowTarget: HTMLElement
  declare readonly thumbArtTarget: HTMLElement
  declare readonly thumbNameTarget: HTMLElement
  declare readonly thumbSubTarget: HTMLElement
  declare readonly flipTarget: HTMLElement
  declare readonly sideTargets: HTMLButtonElement[]

  connect() {
    this.refresh()
  }

  refresh() {
    const name = this.nameTarget.value.trim()
    const rule = this.ruleTarget.value.trim()
    const story = this.storyTarget.value.trim()
    const discount = Math.max(0, parseInt(this.discountTarget.value, 10) || 0)

    this.placeholder(this.frontNameTarget, name, "Nazwa odznaki")
    this.placeholder(this.backNameTarget, name, "Nazwa odznaki")
    this.placeholder(this.frontRulesTarget, rule, "Jak zdobyć…")
    this.backHowTarget.textContent = rule || "Jak zdobyć…"

    this.frontFlavorTarget.textContent = story
    this.frontFlavorTarget.hidden = story === ""

    // A badge worth 0% promises nothing; the mockup still prints "−0% w
    // sklepie", which reads as a reward that is not there.
    this.frontTagTarget.textContent = `−${discount}% w sklepie`
    this.frontTagTarget.hidden = discount === 0

    this.thumbNameTarget.textContent = name || "Nazwa odznaki"
    this.thumbSubTarget.textContent = story || rule

    this.renderArt()
  }

  /**
   * Bound to the image field's crop event, which fires on every animation frame
   * of a drag. Only the picture changes then, so this is deliberately narrower
   * than refresh().
   */
  art() {
    this.renderArt()
  }

  /** The "Zdobyta / Jeszcze niezdobyta" segmented control. */
  side(event: Event) {
    const button = event.currentTarget as HTMLButtonElement
    const down = button.value === "lost"

    this.flipTarget.classList.toggle("gh-flip--down", down)
    this.sideTargets.forEach((other) => {
      other.setAttribute("aria-pressed", String(other === button))
    })
  }

  private renderArt() {
    const art = this.chosenArt
    if (!art) return

    this.frontArtTarget.replaceChildren(art.cloneNode(true))
    this.thumbArtTarget.replaceChildren(art.cloneNode(true))
  }

  /**
   * The artwork inside the checked preset tile — an inline <svg> or, for "Twoja
   * grafika", the <img>. Cloning what the picker already shows means there is
   * nowhere for the two to disagree. Same selector as rank_form_controller:
   * it is entity-agnostic on purpose.
   */
  private get chosenArt(): Element | null {
    const checked = this.element.querySelector<HTMLInputElement>(
      'input[type="radio"][name$="[icon_glyph]"]:checked',
    )

    return checked?.closest("label")?.querySelector("i")?.firstElementChild ?? null
  }

  private placeholder(element: HTMLElement, value: string, fallback: string) {
    element.textContent = value || fallback
    element.classList.toggle("gh-ph", value === "")
  }
}

application.register("badge-form", BadgeFormController)
