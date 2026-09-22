import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/** What anything in the app dispatches to raise a toast. */
export const TOAST_EVENT = "gh:toast"

export interface ToastDetail {
  message: string
  /** Font Awesome class for the leading icon; omit for the default tick. */
  icon?: string
}

/**
 * Confirmations that rise from the bottom and take themselves away.
 *
 * Ported from the mockup's `toast()` (js-expanded/10-core.js:352-356). Two
 * sources feed it: server flash notices, seeded as <template> children by
 * layouts/_flash, and anything in the page dispatching gh:toast on
 * window — which is how the copy buttons say "Skopiowano kod ...".
 *
 * Errors never come here. They stay inline, where they keep still.
 */
class ToastController extends Controller<HTMLElement> {
  static targets = ["seed"]
  static values = { life: { type: Number, default: 3400 } }

  declare readonly seedTargets: HTMLTemplateElement[]
  declare readonly lifeValue: number

  private listener = (event: Event) => {
    const detail = (event as CustomEvent<ToastDetail>).detail

    if (detail?.message) this.show(detail.message, detail.icon)
  }

  connect() {
    window.addEventListener(TOAST_EVENT, this.listener)

    // Drain whatever the server left behind, then discard the templates so a
    // Turbo restoration visit cannot replay them.
    this.seedTargets.forEach((seed) => {
      this.show(seed.content.textContent?.trim() ?? "", seed.dataset.icon)
      seed.remove()
    })
  }

  disconnect() {
    window.removeEventListener(TOAST_EVENT, this.listener)
  }

  show(message: string, icon = "fa-check") {
    if (!message) return

    // Opened BEFORE the node lands, so the live region is already visible when
    // its content changes — announce it first and a screen reader may miss it.
    this.open()

    const toast = document.createElement("div")
    toast.className = "gh-toast"
    toast.setAttribute("role", "status")

    const mark = document.createElement("i")
    mark.className = `fa-solid ${icon}`
    mark.setAttribute("aria-hidden", "true")

    const text = document.createElement("span")
    text.textContent = message

    toast.append(mark, text)
    this.element.append(toast)

    setTimeout(() => {
      toast.remove()
      if (!this.element.firstElementChild) this.close()
    }, this.lifeValue)
  }

  /**
   * The popover calls are guarded and optional: showPopover throws if the
   * popover is already open, and does not exist at all in a browser without
   * the API — where the container is a plain fixed element that is simply
   * always "open" and invisible while empty.
   */
  private open() {
    if (!this.supportsPopover || this.element.matches(":popover-open")) return

    this.element.showPopover()
  }

  private close() {
    if (!this.supportsPopover || !this.element.matches(":popover-open")) return

    this.element.hidePopover()
  }

  private get supportsPopover(): boolean {
    return typeof this.element.showPopover === "function"
  }
}

application.register("toast", ToastController)
