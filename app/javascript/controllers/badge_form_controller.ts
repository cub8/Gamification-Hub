import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

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

    this.frontTagTarget.textContent = `−${discount}% w sklepie`
    this.frontTagTarget.hidden = discount === 0

    this.thumbNameTarget.textContent = name || "Nazwa odznaki"
    this.thumbSubTarget.textContent = story || rule

    this.renderArt()
  }

  art() {
    this.renderArt()
  }

  side(event: Event) {
    const button = event.currentTarget as HTMLButtonElement
    const down = button.value === "lost"

    this.flipTarget.classList.toggle("gh-flip-card--down", down)
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

  private get chosenArt(): Element | null {
    const checked = this.element.querySelector<HTMLInputElement>(
      'input[type="radio"][name$="[icon_glyph]"]:checked',
    )

    return checked?.closest("label")?.querySelector("i")?.firstElementChild ?? null
  }

  private placeholder(element: HTMLElement, value: string, fallback: string) {
    element.textContent = value || fallback
    element.classList.toggle("gh-placeholder-text", value === "")
  }
}

application.register("badge-form", BadgeFormController)
