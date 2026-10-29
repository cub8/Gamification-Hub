import { application } from "@controllers/application"
import { Controller, type ActionEvent } from "@hotwired/stimulus"
import { TOAST_EVENT, type ToastDetail } from "@controllers/toast_controller"
import { interpolate, pluralize, type PluralForms } from "@utils/i18n"

interface Wording {
  cells: PluralForms
  students: PluralForms
  recipients: PluralForms
  cell_empty: string
  cell_marked: string
  locked: string
}

class GradingController extends Controller<HTMLElement> {
  static targets = [
    "search", "row", "cell", "rowPending",
    "barEmpty", "barActive", "barCells", "barStudents", "barSum", "clear", "submit",
    "dialog", "reviewSum", "reviewStudents", "reviewRow", "reviewChip", "reviewRowSum",
    "reviewConfirmSum",
  ]

  static values = {
    i18n: Object,
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
  declare readonly i18nValue: Wording

  connect() {
    this.clearTarget.hidden = false
    this.refresh()
  }

  toggle(event: Event) {
    this.relabel(event.target as HTMLInputElement)
    this.refresh()
  }

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

  filter() {
    const query = fold(this.searchTarget.value.trim())

    this.rowTargets.forEach((row) => {
      row.hidden = !fold(row.dataset.ghName ?? "").includes(query)
    })

    this.refresh()
  }

  locked() {
    const detail: ToastDetail = {
      message: this.i18nValue.locked,
      icon: "fa-lock",
    }

    window.dispatchEvent(new CustomEvent(TOAST_EVENT, { detail }))
  }

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

    this.barCellsTarget.textContent = pluralize(this.i18nValue.cells, count)
    this.barStudentsTarget.textContent = pluralize(this.i18nValue.students, students)
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
    this.reviewStudentsTarget.textContent = pluralize(this.i18nValue.recipients, students)
    this.reviewConfirmSumTarget.textContent = String(sum)
  }

  private relabel(box: HTMLInputElement) {
    const template = box.checked ? this.i18nValue.cell_marked : this.i18nValue.cell_empty

    box.setAttribute("aria-label", interpolate(template, { label: box.dataset.ghLabel ?? "" }))
  }

  private get visibleCells(): HTMLElement[] {
    return this.cellTargets.filter((cell) => !(cell.closest("tr") as HTMLElement)?.hidden)
  }

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

function fold(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ł/g, "l")
}

application.register("grading", GradingController)
