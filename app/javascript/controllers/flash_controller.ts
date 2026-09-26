import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class FlashController extends Controller {
  static targets = ["message"]

  declare readonly messageTargets: HTMLElement[]

  dismiss(event: Event) {
    const button = event.currentTarget as HTMLElement
    const message = this.messageTargets.find((candidate) => candidate.contains(button))

    message?.remove()

    if (this.messageTargets.length === 0) this.element.remove()
  }
}

application.register("flash", FlashController)
