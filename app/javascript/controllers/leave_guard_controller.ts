import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

type VisitEvent = CustomEvent<{ url: string }>

class LeaveGuardController extends Controller<HTMLElement> {
  static targets = ["form", "dialog"]

  declare readonly formTarget: HTMLFormElement
  declare readonly hasFormTarget: boolean
  declare readonly dialogTarget: HTMLDialogElement

  private bypass = false
  private pendingUrl: string | null = null

  connect() {
    window.addEventListener("turbo:before-visit", this.onBeforeVisit)
    window.addEventListener("beforeunload", this.onBeforeUnload)
  }

  disconnect() {
    window.removeEventListener("turbo:before-visit", this.onBeforeVisit)
    window.removeEventListener("beforeunload", this.onBeforeUnload)
  }

  // Submitting the form saves the changes, so leaving afterwards is fine.
  submitting() {
    this.bypass = true
  }

  stay() {
    this.pendingUrl = null
    this.dialogTarget.close()
  }

  leave() {
    const url = this.pendingUrl

    this.bypass = true
    this.pendingUrl = null
    this.dialogTarget.close()

    if (url) Turbo.visit(url)
  }

  closeOnBackdrop(event: MouseEvent) {
    if (event.target !== event.currentTarget) return

    this.stay()
  }

  private onBeforeVisit = (event: Event) => {
    if (!this.guarding) return

    event.preventDefault()
    this.pendingUrl = (event as VisitEvent).detail.url

    if (!this.dialogTarget.open) this.dialogTarget.showModal()
  }

  private onBeforeUnload = (event: BeforeUnloadEvent) => {
    if (!this.guarding) return

    event.preventDefault()
  }

  private get guarding(): boolean {
    return !this.bypass && this.dirty
  }

  private get dirty(): boolean {
    if (!this.hasFormTarget) return false

    return Array.from(this.formTarget.elements).some((field) => {
      if (field instanceof HTMLInputElement && ["checkbox", "radio"].includes(field.type)) {
        return field.checked !== field.defaultChecked
      }

      if (field instanceof HTMLInputElement || field instanceof HTMLTextAreaElement) {
        return field.type !== "hidden" && field.value !== field.defaultValue
      }

      return false
    })
  }
}

application.register("leave-guard", LeaveGuardController)
