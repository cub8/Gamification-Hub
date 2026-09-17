import { application } from "@redesign/application"
import { Controller, type ActionEvent } from "@hotwired/stimulus"
import { TOAST_EVENT, type ToastDetail } from "@redesign/toast_controller"

/**
 * The grading table — mockup js-expanded/30-main.js:169-193, 229-248.
 *
 * Three cell states (DECISIONS.md:31): empty, marked now, and awarded. The
 * third is not a control at all — the server renders it without an input,
 * because the award behind it cannot be taken back — so this controller can
 * only ever move a cell between the first two.
 *
 * The marked look comes from `:has(input:checked)` in CSS, not from here, so a
 * ticked cell reads as ticked with JavaScript off. What this adds is the
 * arithmetic — row totals, the award bar, the review dialog — and the column
 * and search controls that arithmetic depends on.
 *
 * It writes no markup. The review dialog holds the whole matrix, hidden, and
 * this unhides the part that is marked.
 */
class GradingController extends Controller<HTMLElement> {
  static targets = [
    "search", "row", "cell", "rowPending",
    "barEmpty", "barActive", "barCells", "barStudents", "barSum", "clear", "submit",
    "dialog", "reviewSum", "reviewStudents", "reviewRow", "reviewChip", "reviewRowSum",
    "reviewConfirmSum",
  ]

  static values = {
    cells: Array,
    students: Array,
    recipients: Array,
    states: Array,
    currency: String,
  }

  declare readonly searchTarget: HTMLInputElement
  declare readonly rowTargets: HTMLElement[]
  declare readonly cellTargets: HTMLElement[]
  declare readonly barEmptyTarget: HTMLElement
  declare readonly barActiveTarget: HTMLElement
  declare readonly barCellsTarget: HTMLElement
  declare readonly barStudentsTarget: HTMLElement
  declare readonly barSumTarget: HTMLElement
  declare readonly clearTarget: HTMLButtonElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly dialogTarget: HTMLDialogElement
  declare readonly reviewSumTarget: HTMLElement
  declare readonly reviewStudentsTarget: HTMLElement
  declare readonly reviewRowTargets: HTMLElement[]
  declare readonly reviewChipTargets: HTMLElement[]
  declare readonly reviewConfirmSumTarget: HTMLElement
  declare readonly cellsValue: string[]
  declare readonly studentsValue: string[]
  declare readonly recipientsValue: string[]
  declare readonly statesValue: string[]
  declare readonly currencyValue: string

  connect() {
    // Only useful once this is running: without it, unticking a box is the
    // clearing mechanism and it works better.
    this.clearTarget.hidden = false
    this.refresh()
  }

  toggle(event: Event) {
    this.relabel(event.target as HTMLInputElement)
    this.refresh()
  }

  /**
   * "Wszyscy". Visible rows only — with a search running, the teacher is
   * looking at a subset and means that subset — and never an awarded cell,
   * which has no input to tick. Marks the column unless it is already
   * complete, in which case it clears it.
   */
  toggleColumn(event: ActionEvent) {
    const column = Number(event.params.column)
    const boxes = this.visibleCells.filter((cell) => this.columnOf(cell) === column).map(boxIn)
    const marking = boxes.some((box) => box && !box.checked)

    boxes.forEach((box) => {
      if (!box) return

      box.checked = marking
      this.relabel(box)
    })

    this.refresh()
  }

  clear() {
    this.cellTargets.forEach((cell) => {
      const box = boxIn(cell)

      if (!box?.checked) return

      box.checked = false
      this.relabel(box)
    })

    this.refresh()
  }

  /** Hides rows rather than re-rendering, which is also what the mockup does. */
  filter() {
    const query = fold(this.searchTarget.value.trim())

    this.rowTargets.forEach((row) => {
      row.hidden = !fold(row.dataset.ghName ?? "").includes(query)
    })

    this.refresh()
  }

  /**
   * An awarded cell is not a control, so clicking it does nothing — which
   * reads as the page being broken unless it says why.
   */
  locked() {
    const detail: ToastDetail = {
      message: "To pole jest już przyznane i nie można go cofnąć.",
      icon: "fa-lock",
    }

    window.dispatchEvent(new CustomEvent(TOAST_EVENT, { detail }))
  }

  /**
   * Intercepts the submit to show what is about to happen first. With
   * JavaScript off the same button saves directly — a worse screen, but not a
   * broken one.
   */
  review(event: Event) {
    const marked = this.markedCells

    if (marked.length === 0) return

    event.preventDefault()
    this.paintReview(marked)
    this.dialogTarget.showModal()
  }

  closeReview() {
    this.dialogTarget.close()
  }

  closeOnBackdrop(event: MouseEvent) {
    if (event.target !== event.currentTarget) return

    this.dialogTarget.close()
  }

  // --- painting ------------------------------------------------------------

  private refresh() {
    this.paintRowTotals()
    this.paintBar()
  }

  private paintRowTotals() {
    this.rowTargets.forEach((row) => {
      const pending = this.cellsIn(row)
        .filter((cell) => boxIn(cell)?.checked)
        .reduce((total, cell) => total + rewardOf(cell), 0)

      const slot = row.querySelector<HTMLElement>("[data-grading-target='rowPending']")

      if (!slot) return

      slot.hidden = pending === 0
      slot.textContent = `+${pending}`
    })
  }

  private paintBar() {
    const marked = this.markedCells
    const count = marked.length

    this.barEmptyTarget.hidden = count > 0
    this.barActiveTarget.hidden = count === 0
    this.submitTarget.disabled = count === 0

    if (count === 0) return

    const students = new Set(marked.map((cell) => this.studentOf(cell))).size
    const sum = marked.reduce((total, cell) => total + rewardOf(cell), 0)

    this.barCellsTarget.textContent =
      `Zaznaczone teraz: ${count} ${plural(count, this.cellsValue)}`
    this.barStudentsTarget.textContent =
      `u ${students} ${plural(students, this.studentsValue)}, razem`
    this.barSumTarget.textContent = `+${sum}`
  }

  private paintReview(marked: HTMLElement[]) {
    const byStudent = new Map<number, HTMLElement[]>()
    const marks = new Set<string>()

    marked.forEach((cell) => {
      const student = this.studentOf(cell)

      byStudent.set(student, [...(byStudent.get(student) ?? []), cell])
      marks.add(`${student}:${this.columnOf(cell)}`)
    })

    this.reviewChipTargets.forEach((chip) => {
      chip.hidden = !marks.has(`${chip.dataset.ghStudent}:${chip.dataset.ghColumn}`)
    })

    this.reviewRowTargets.forEach((row) => {
      const cells = byStudent.get(Number(row.dataset.ghStudent)) ?? []

      row.hidden = cells.length === 0

      const slot = row.querySelector<HTMLElement>("[data-grading-target='reviewRowSum']")
      if (slot) slot.textContent = `+${cells.reduce((total, cell) => total + rewardOf(cell), 0)}`
    })

    const sum = marked.reduce((total, cell) => total + rewardOf(cell), 0)
    const students = byStudent.size

    this.reviewSumTarget.textContent = String(sum)
    this.reviewStudentsTarget.textContent = `${students} ${plural(students, this.recipientsValue)}`
    this.reviewConfirmSumTarget.textContent = String(sum)
  }

  /** "{student}, {kategoria}: {puste|zaznaczone|przyznane}" */
  private relabel(box: HTMLInputElement) {
    const [empty, marked] = this.statesValue

    box.setAttribute("aria-label", `${box.dataset.ghLabel ?? ""}: ${box.checked ? marked : empty}`)
  }

  // --- reading the DOM -----------------------------------------------------

  private get visibleCells(): HTMLElement[] {
    return this.cellTargets.filter((cell) => !(cell.closest("tr") as HTMLElement)?.hidden)
  }

  /** Marked cells in hidden rows still count: they are still going to save. */
  private get markedCells(): HTMLElement[] {
    return this.cellTargets.filter((cell) => boxIn(cell)?.checked)
  }

  private cellsIn(row: HTMLElement): HTMLElement[] {
    return Array.from(row.querySelectorAll<HTMLElement>("[data-grading-target='cell']"))
  }

  private columnOf(cell: HTMLElement): number {
    return Number(cell.dataset.gradingColumn)
  }

  private studentOf(cell: HTMLElement): number {
    return Number((cell.closest("tr") as HTMLElement)?.dataset.ghStudent)
  }
}

function boxIn(cell: HTMLElement): HTMLInputElement | null {
  return cell.querySelector<HTMLInputElement>("input[type=checkbox]")
}

function rewardOf(cell: HTMLElement): number {
  const parsed = Number.parseInt(cell.dataset.gradingReward ?? "", 10)

  return Number.isFinite(parsed) ? parsed : 0
}

/** Diacritics folded, so "lukasz" finds "Łukasz" — as list_search does. */
function fold(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ł/g, "l")
}

function plural(count: number, forms: string[]): string {
  const [one, few, many] = forms
  const last = count % 10
  const teens = count % 100

  if (count === 1) return one
  if (last >= 2 && last <= 4 && (teens < 12 || teens > 14)) return few

  return many
}

application.register("grading", GradingController)
