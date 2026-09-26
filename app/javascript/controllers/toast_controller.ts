import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

export const TOAST_EVENT = "gh:toast"

export interface ToastDetail {
  message: string
  icon?: string
}

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
