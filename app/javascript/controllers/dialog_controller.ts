import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class DialogController extends Controller<HTMLDialogElement> {
  static targets = ["frame"]

  declare readonly frameTarget: HTMLElement

  open() {
    if (this.isEmpty || this.element.open) return

    this.element.showModal()
  }

  close() {
    this.element.close()
  }

  closeOnBackdrop(event: MouseEvent) {
    if (event.target !== event.currentTarget) return

    this.element.close()
  }

  onClose() {
    this.frameTarget.innerHTML = ""
    this.frameTarget.removeAttribute("src")
    this.frameTarget.removeAttribute("complete")
  }

  private get isEmpty(): boolean {
    return this.frameTarget.innerHTML.trim() === ""
  }
}

application.register("dialog", DialogController)
