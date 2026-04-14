import { Controller } from "@hotwired/stimulus"
import { application } from "@controllers/application"

class BulkCreateModalController extends Controller {
  static targets = ["templateSelect", "baseNameInput"]

  declare readonly templateSelectTarget: HTMLSelectElement
  declare readonly baseNameInputTarget: HTMLInputElement

  fillBaseName() {
    const select = this.templateSelectTarget
    const selected = select.options[select.selectedIndex]
    this.baseNameInputTarget.value = selected.dataset.baseName || ""
  }
}

application.register("bulk-create-modal", BulkCreateModalController)
