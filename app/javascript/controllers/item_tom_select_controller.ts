import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

class ItemTomSelectController extends Controller {
  private select?: TomSelect

  connect() {
    const el = this.element as HTMLSelectElement
    const plugins = el.multiple ? ["remove_button"] : ["clear_button"]

    this.select = new TomSelect(el, {
      plugins,
      create: false,
      hidePlaceholder: true,
    })
  }

  disconnect() {
    this.select?.destroy()
  }
}

application.register("item-tom-select", ItemTomSelectController)
