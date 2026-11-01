import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { fold } from "@utils/fold"

class ListSearchController extends Controller<HTMLElement> {
  static targets = ["input", "filter", "row", "count", "empty", "emptyQuery"]
  static values = { total: Number, of: String }

  declare readonly inputTarget: HTMLInputElement
  declare readonly filterTargets: HTMLElement[]
  declare readonly rowTargets: HTMLElement[]
  declare readonly countTarget: HTMLElement
  declare readonly emptyTarget: HTMLElement
  declare readonly emptyQueryTarget: HTMLElement
  declare readonly totalValue: number
  declare readonly ofValue: string

  connect() {
    this.filter()
  }

  filter() {
    const typed = this.inputTarget.value.trim()
    const query = fold(typed)
    const active = this.activeFilters()

    const shown = this.rowTargets.filter((row) => {
      const hit = fold(row.dataset.listSearchName ?? "").includes(query) &&
        active.every(({ key, values }) => matches(row, key, values))

      row.hidden = !hit

      return hit
    })

    this.countTarget.textContent = `${shown.length} ${this.ofValue} ${this.totalValue}`
    this.emptyQueryTarget.textContent = typed === "" ? "" : ` „${typed}”`
    this.emptyTarget.hidden = shown.length > 0
  }

  private activeFilters(): { key: string; values: string[] }[] {
    return this.filterTargets
      .map((element) => ({
        key: element.dataset.listSearchKey ?? "filter",
        values: selectedValues(element),
      }))
      .filter(({ values }) => values.length > 0)
  }
}

function selectedValues(element: HTMLElement): string[] {
  if (element instanceof HTMLSelectElement) {
    return element.value === "" ? [] : [element.value]
  }

  return Array.from(element.querySelectorAll<HTMLInputElement>('input[type="checkbox"]:checked'))
    .map((box) => box.value)
}

function matches(row: HTMLElement, key: string, values: string[]): boolean {
  const attribute = `listSearch${key.charAt(0).toUpperCase()}${key.slice(1)}`
  const tokens = (row.dataset[attribute] ?? "").split(" ")

  return values.some((value) => tokens.includes(value))
}

application.register("list-search", ListSearchController)
