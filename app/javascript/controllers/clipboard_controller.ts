import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { TOAST_EVENT, type ToastDetail } from "@controllers/toast_controller"

class ClipboardController extends Controller<HTMLElement> {
  static targets = ["label", "icon"]
  static values = {
    text: String,
    done: String,
    message: String,
    resetAfter: { type: Number, default: 2000 },
  }

  declare readonly labelTarget: HTMLElement
  declare readonly hasLabelTarget: boolean
  declare readonly iconTarget: HTMLElement
  declare readonly hasIconTarget: boolean
  declare readonly textValue: string
  declare readonly doneValue: string
  declare readonly messageValue: string
  declare readonly resetAfterValue: number

  private original = { label: "", icon: "" }
  private timer?: ReturnType<typeof setTimeout>

  connect() {
    if (!navigator.clipboard) this.element.hidden = true
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  async copy() {
    await navigator.clipboard.writeText(this.textValue)

    this.announce()
    this.acknowledge()

    if (this.timer) clearTimeout(this.timer)
    this.timer = setTimeout(() => this.reset(), this.resetAfterValue)
  }

  private announce() {
    const detail: ToastDetail = { message: this.messageValue }

    window.dispatchEvent(new CustomEvent<ToastDetail>(TOAST_EVENT, { detail }))
  }

  private acknowledge() {
    if (this.hasLabelTarget) {
      this.original.label ||= this.labelTarget.textContent ?? ""
      this.labelTarget.textContent = this.doneValue
    }

    if (this.hasIconTarget) {
      this.original.icon ||= this.iconTarget.className
      this.iconTarget.className = "fa-solid fa-check"
    }

    this.element.title = this.doneValue
  }

  private reset() {
    if (this.hasLabelTarget) this.labelTarget.textContent = this.original.label
    if (this.hasIconTarget) this.iconTarget.className = this.original.icon

    this.element.title = this.element.dataset.clipboardTitle ?? ""
  }
}

application.register("clipboard", ClipboardController)
