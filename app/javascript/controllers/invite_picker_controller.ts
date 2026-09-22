import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * "Pokaż kod dla studentów" (students#index quick-invite dialog).
 *
 * NEVER WRITES HTML, same rule as badge-picker: every active invite's
 * QR/code/stat block is server-rendered up front, all hidden but the first —
 * this only toggles which one is visible when the <select> changes.
 */
class InvitePickerController extends Controller<HTMLElement> {
  static targets = ["select", "block"]

  declare readonly selectTarget: HTMLSelectElement
  declare readonly blockTargets: HTMLElement[]

  connect() {
    this.pick()
  }

  pick() {
    const chosen = this.selectTarget.value

    this.blockTargets.forEach((block) => {
      block.hidden = block.dataset.invitePickerFor !== chosen
    })
  }
}

application.register("invite-picker", InvitePickerController)
