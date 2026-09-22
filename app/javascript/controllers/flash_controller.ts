import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Dismissible flash messages.
 *
 * Replaces Bootstrap's alert JS (data-bs-dismiss="alert"). The controller sits
 * on the list wrapper; each message is a target and each close button
 * dispatches flash#dismiss. When the last message goes, the wrapper goes too,
 * so its bottom margin does not leave a gap.
 */
class FlashController extends Controller {
  static targets = ["message"]

  declare readonly messageTargets: HTMLElement[]

  dismiss(event: Event) {
    const button = event.currentTarget as HTMLElement
    const message = this.messageTargets.find((candidate) => candidate.contains(button))

    message?.remove()

    // messageTargets is a live query, so this reflects the removal.
    if (this.messageTargets.length === 0) this.element.remove()
  }
}

application.register("flash", FlashController)
