import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

class TomSelectBasicController extends Controller {
  private select?: TomSelect

  connect() {
    this.select = new TomSelect(this.element as HTMLSelectElement, {
      create: false,
      maxItems: 1,
    })
  }

  disconnect() {
    this.select?.destroy()
  }
}

application.register("tom-select-basic", TomSelectBasicController)
