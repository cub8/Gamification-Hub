import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

class TomSelectBasicController extends Controller {
  private select?: TomSelect

  connect() {
    const el = this.element as HTMLSelectElement
    const plugins = el.multiple ? ["remove_button"] : ["clear_button"]

    this.select = new TomSelect(el, {
      plugins: ["dropdown_input", ...plugins],
      create: false,
      hidePlaceholder: true,
    })
  }

  disconnect() {
    this.select?.destroy()
  }
}

application.register("tom-select-basic", TomSelectBasicController)
