import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

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
