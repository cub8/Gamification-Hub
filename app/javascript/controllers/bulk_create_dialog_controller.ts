import { Controller } from "@hotwired/stimulus"
import { application } from "@controllers/application"

class BulkCreateDialogController extends Controller {
  static targets = ["dialog", "templateSelect", "baseNameInput"]

  declare readonly dialogTarget: HTMLDialogElement
  declare readonly templateSelectTarget: HTMLSelectElement
  declare readonly baseNameInputTarget: HTMLInputElement

  open(event: Event) {
    event.preventDefault()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  fillBaseName() {
    const select = this.templateSelectTarget
    const selected = select.options[select.selectedIndex]
    this.baseNameInputTarget.value = selected.dataset.baseName || ""
  }
}

application.register("bulk-create-dialog", BulkCreateDialogController)
