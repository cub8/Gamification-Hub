import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class CsvCancelController extends Controller<HTMLElement> {
  static values = { resource: String }

  declare readonly resourceValue: string

  cancel() {
    const input = document.querySelector<HTMLInputElement>(
      `input[data-group-wizard-target="csvFile"][data-resource="${this.resourceValue}"]`,
    )
    if (!input) return

    input.value = ""
    input.dispatchEvent(new Event("change", { bubbles: true }))
  }
}

application.register("csv-cancel", CsvCancelController)
