import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class TableSearchController extends Controller {
  static targets = ["input", "table"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly tableTarget: HTMLElement

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    this.tableTarget.querySelectorAll<HTMLElement>("tbody tr").forEach(row => {
      const name = row.querySelector<HTMLElement>("td.sticky-col")?.textContent?.toLowerCase() ?? ""
      row.hidden = query.length > 0 && !name.includes(query)
    })
  }
}

application.register("table-search", TableSearchController)
