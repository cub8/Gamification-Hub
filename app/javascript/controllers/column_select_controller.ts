import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class ColumnSelectController extends Controller {
  toggleColumn(event: Event) {
    const header = event.currentTarget as HTMLInputElement
    const colIndex = header.dataset.colIndex!

    this.element
      .querySelectorAll<HTMLInputElement>(`tbody tr:not([hidden]) input[type="checkbox"][data-col-index="${colIndex}"]:not(:disabled)`)
      .forEach(cb => { cb.checked = header.checked })
  }
}

application.register("column-select", ColumnSelectController)
