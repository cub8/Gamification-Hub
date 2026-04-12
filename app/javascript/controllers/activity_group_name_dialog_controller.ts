import { Controller } from "@hotwired/stimulus"
import { application } from "@controllers/application"

class ActivityGroupNameDialogController extends Controller {
  static targets = ["nameInput", "dialog"]
  static values = {
    newUrl: String,
    defaultName: String,
  }

  declare readonly nameInputTarget: HTMLInputElement
  declare readonly dialogTarget: HTMLDialogElement
  declare newUrlValue: string
  declare defaultNameValue: string

  open(event: Event) {
    event.preventDefault()
    this.nameInputTarget.value = this.defaultNameValue
    this.dialogTarget.showModal()
    this.nameInputTarget.select()
  }

  confirm() {
    const name = this.nameInputTarget.value.trim() || this.defaultNameValue
    window.location.href = `${this.newUrlValue}?name=${encodeURIComponent(name)}`
  }

  close() {
    this.dialogTarget.close()
  }
}

application.register("activity-group-name-dialog", ActivityGroupNameDialogController)
