import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The search-first picker in "Dodaj nauczyciela" (mockup 30-rk.js `mAddT` /
 * `resHtml`).
 *
 * Every candidate is server-rendered and hidden; this only decides which ones
 * are shown. The one thing it builds is the <mark> around the matched part of
 * a name, and that is assembled from DOM nodes with textContent — never from
 * an HTML string — so a name can carry any character without becoming markup.
 *
 * Nothing here is fetched. full_name and email are encrypted in the database,
 * so there is no query to run: the pool arrives with the dialog and is matched
 * here, exactly as the mockup does.
 *
 * No Polish in this file. The three plural forms and the overflow suffix
 * arrive as values, and the Polish plural RULE is grammar, not copy — the same
 * rule the server keeps in Redesign::Plural.
 */
class TeacherPickerController extends Controller<HTMLFormElement> {
  static targets = ["input", "row", "name", "count", "hint", "results", "overflow", "empty", "emptyQuery"]
  static values = {
    min: { type: Number, default: 2 },
    max: { type: Number, default: 8 },
    one: String,
    few: String,
    many: String,
    overflow: String,
  }

  declare readonly inputTarget: HTMLInputElement
  declare readonly rowTargets: HTMLElement[]
  declare readonly countTarget: HTMLElement
  declare readonly hintTarget: HTMLElement
  declare readonly resultsTarget: HTMLElement
  declare readonly overflowTarget: HTMLElement
  declare readonly emptyTarget: HTMLElement
  declare readonly emptyQueryTarget: HTMLElement
  declare readonly minValue: number
  declare readonly maxValue: number
  declare readonly oneValue: string
  declare readonly fewValue: string
  declare readonly manyValue: string
  declare readonly overflowValue: string

  /**
   * Enter in the search box must not submit.
   *
   * The whole list is one form, so the browser would press the first submit
   * button in it — adding whichever candidate happens to sort first, which is
   * never what the typing meant. Every add is a deliberate click on a row.
   */
  noSubmit(event: KeyboardEvent) {
    event.preventDefault()
  }

  filter() {
    const typed = this.inputTarget.value.trim()
    const query = fold(typed)

    // Under the threshold nothing is a result yet — not even "no results",
    // which for an empty box would read as "there is nobody here".
    if (query.length < this.minValue) {
      this.show({ hint: true })
      this.rowTargets.forEach((row) => this.plain(row))

      return
    }

    const hits = this.rowTargets.filter((row) => (row.dataset.teacherPickerKey ?? "").includes(query))

    if (hits.length === 0) {
      this.rowTargets.forEach((row) => this.plain(row))
      this.emptyQueryTarget.textContent = `„${typed}”.`
      this.show({ empty: true })

      return
    }

    const shown = hits.slice(0, this.maxValue)

    this.rowTargets.forEach((row) => this.plain(row))
    shown.forEach((row) => {
      row.hidden = false
      this.highlight(row, query)
    })

    const over = hits.length > this.maxValue

    this.countTarget.textContent = `${hits.length} ${this.plural(hits.length)}${over ? this.overflowValue : ""}`
    this.show({ count: true, results: true, overflow: over })
  }

  /** Hidden and back to its plain name, which is also the reset for a row that stays shown. */
  private plain(row: HTMLElement) {
    row.hidden = true

    const name = row.querySelector<HTMLElement>("[data-teacher-picker-target='name']")

    if (name && name.childElementCount > 0) name.textContent = name.textContent
  }

  /**
   * Wraps the matched run of the name in <mark>. The query may have matched on
   * the e-mail instead, in which case the name has nothing to mark and is left
   * alone.
   *
   * Folding maps one character to one character, so an index into the folded
   * name is an index into the name itself.
   */
  private highlight(row: HTMLElement, query: string) {
    const name = row.querySelector<HTMLElement>("[data-teacher-picker-target='name']")

    if (!name) return

    const text = name.textContent ?? ""
    const at = fold(text).indexOf(query)

    if (at < 0) return

    const mark = document.createElement("mark")

    mark.textContent = text.slice(at, at + query.length)

    name.replaceChildren(
      document.createTextNode(text.slice(0, at)),
      mark,
      document.createTextNode(text.slice(at + query.length)),
    )
  }

  /** Exactly one of hint / empty / (count + results) is ever on screen. */
  private show(state: { hint?: boolean; empty?: boolean; count?: boolean; results?: boolean; overflow?: boolean }) {
    this.hintTarget.hidden = !state.hint
    this.emptyTarget.hidden = !state.empty
    this.countTarget.hidden = !state.count
    this.resultsTarget.hidden = !state.results
    this.overflowTarget.hidden = !state.overflow
  }

  /** 1 -> one, 2-4 -> few, otherwise many, with the usual 12-14 exception. */
  private plural(count: number): string {
    const n = Math.abs(count)

    if (n === 1) return this.oneValue

    const lastOne = n % 10
    const lastTwo = n % 100

    return lastOne >= 2 && lastOne <= 4 && (lastTwo < 12 || lastTwo > 14) ? this.fewValue : this.manyValue
  }
}

/** Diacritics folded, so "lukasz" finds "Łukasz". Mirrors Redesign::TeacherPool.fold. */
function fold(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ł/g, "l")
}

application.register("teacher-picker", TeacherPickerController)
