import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Dismissible flash messages.
 *
 * Replaces Bootstrap's alert JS (data-bs-dismiss="alert"). The controller sits
 * on the message wrapper; the close button dispatches flash#dismiss.
 */
class FlashController extends Controller {
  dismiss(event: Event) {
    const message = (event.currentTarget as HTMLElement).closest<HTMLElement>("[role]")

    if (message) {
      message.remove()
    } else {
      this.element.remove()
    }
  }
}

application.register("flash", FlashController)
