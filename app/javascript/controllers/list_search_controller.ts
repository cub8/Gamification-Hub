import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Instant filtering of a list of rows, with a "N z M" counter.
 *
 * Client-side on purpose, exactly like group_search: the whole list is on the
 * page already, so matching it costs nothing and it narrows as you type. The
 * mockup does the same and deliberately does not re-render — it sets `hidden`
 * on each row and rewrites the counter (30-lists.js:67).
 *
 * Entity-agnostic: a row announces its own searchable text with
 * `data-list-search-name`, so the student list is only the first caller.
 *
 * No Polish in this file. The connector in the counter arrives as a value,
 * like every other controller here.
 */
class ListSearchController extends Controller<HTMLElement> {
  static targets = ["input", "row", "count", "empty", "emptyQuery"]
  static values = { total: Number, of: String }

  declare readonly inputTarget: HTMLInputElement
  declare readonly rowTargets: HTMLElement[]
  declare readonly countTarget: HTMLElement
  declare readonly emptyTarget: HTMLElement
  declare readonly emptyQueryTarget: HTMLElement
  declare readonly totalValue: number
  declare readonly ofValue: string

  filter() {
    const typed = this.inputTarget.value.trim()
    const query = fold(typed)

    const shown = this.rowTargets.filter((row) => {
      const hit = fold(row.dataset.listSearchName ?? "").includes(query)

      row.hidden = !hit

      return hit
    })

    this.countTarget.textContent = `${shown.length} ${this.ofValue} ${this.totalValue}`
    this.emptyQueryTarget.textContent = `„${typed}”`
    this.emptyTarget.hidden = shown.length > 0
  }
}

/**
 * Diacritics folded, so "lukasz" finds "Łukasz". The teacher typing a name
 * into a hurry is not going to reach for the ogonek, and the mockup's plain
 * `includes` would find nothing.
 */
function fold(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ł/g, "l")
}

application.register("list-search", ListSearchController)
