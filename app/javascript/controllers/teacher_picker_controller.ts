import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

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

  noSubmit(event: KeyboardEvent) {
    event.preventDefault()
  }

  filter() {
    const typed = this.inputTarget.value.trim()
    const query = fold(typed)

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

  private plain(row: HTMLElement) {
    row.hidden = true

    const name = row.querySelector<HTMLElement>("[data-teacher-picker-target='name']")

    if (name && name.childElementCount > 0) name.textContent = name.textContent
  }

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

  private show(state: { hint?: boolean; empty?: boolean; count?: boolean; results?: boolean; overflow?: boolean }) {
    this.hintTarget.hidden = !state.hint
    this.emptyTarget.hidden = !state.empty
    this.countTarget.hidden = !state.count
    this.resultsTarget.hidden = !state.results
    this.overflowTarget.hidden = !state.overflow
  }

  private plural(count: number): string {
    const n = Math.abs(count)

    if (n === 1) return this.oneValue

    const lastOne = n % 10
    const lastTwo = n % 100

    return lastOne >= 2 && lastOne <= 4 && (lastTwo < 12 || lastTwo > 14) ? this.fewValue : this.manyValue
  }
}

function fold(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ł/g, "l")
}

application.register("teacher-picker", TeacherPickerController)
