import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

// An optional `filter` select narrows rows further by their
// data-list-search-filter value; an empty selection shows every row.
class ListSearchController extends Controller<HTMLElement> {
  static targets = ["input", "filter", "row", "count", "empty", "emptyQuery"]
  static values = { total: Number, of: String }

  declare readonly inputTarget: HTMLInputElement
  declare readonly filterTarget: HTMLSelectElement
  declare readonly hasFilterTarget: boolean
  declare readonly rowTargets: HTMLElement[]
  declare readonly countTarget: HTMLElement
  declare readonly emptyTarget: HTMLElement
  declare readonly emptyQueryTarget: HTMLElement
  declare readonly totalValue: number
  declare readonly ofValue: string

  filter() {
    const typed = this.inputTarget.value.trim()
    const query = fold(typed)
    const selected = this.hasFilterTarget ? this.filterTarget.value : ""

    const shown = this.rowTargets.filter((row) => {
      const hit = fold(row.dataset.listSearchName ?? "").includes(query) &&
        (selected === "" || row.dataset.listSearchFilter === selected)

      row.hidden = !hit

      return hit
    })

    this.countTarget.textContent = `${shown.length} ${this.ofValue} ${this.totalValue}`
    this.emptyQueryTarget.textContent = `„${typed}”`
    this.emptyTarget.hidden = shown.length > 0
  }
}

function fold(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ł/g, "l")
}

application.register("list-search", ListSearchController)
