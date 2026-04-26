import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

class ItemTomSelectController extends Controller {
  private select?: TomSelect

  connect() {
    
    const el = this.element as HTMLSelectElement

    this.select = new TomSelect(el, {
      plugins: ['remove_button'],
      create: false,
      sortField: [
        {
          field: "text",
          direction: "asc"
        }
      ]
    })
  }

  disconnect() {
    this.select?.destroy()
  }
}

application.register("item-tom-select", ItemTomSelectController)
