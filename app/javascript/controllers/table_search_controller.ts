import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class TableSearchController extends Controller {
  static targets = ["input", "table", "select"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly tableTarget: HTMLElement
  declare readonly selectTarget: HTMLSelectElement
  declare readonly hasSelectTarget: boolean

  // Rows match on data-search-text when present, falling back to the sticky name column.
  // An optional select target narrows rows further by their data-filter-value.
  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const selected = this.hasSelectTarget ? this.selectTarget.value : ""

    this.tableTarget.querySelectorAll<HTMLElement>("tbody tr").forEach((row) => {
      const text = (row.dataset.searchText ?? row.querySelector<HTMLElement>("td.sticky-col")?.textContent ?? "").toLowerCase()
      const matchesQuery = query.length === 0 || text.includes(query)
      const matchesSelect = selected === "" || row.dataset.filterValue === selected
      row.hidden = !(matchesQuery && matchesSelect)
    })
  }
}

application.register("table-search", TableSearchController)
