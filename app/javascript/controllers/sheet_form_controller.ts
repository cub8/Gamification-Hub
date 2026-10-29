import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { interpolate, pluralize, type PluralForms } from "@utils/i18n"

interface Wording {
  columns: PluralForms
  dirty: string
  clean: string
  name_label: string
  reward_label: string
  story_label: string
  destroy_column: string
  destroy_category: string
}

class SheetFormController extends Controller<HTMLElement> {
  static targets = [
    "form", "list", "blank", "row", "position", "name", "reward", "hide", "destroy",
    "hideIcon", "hiddenTag", "rewardNote", "up", "down",
    "summaryCount", "summaryMax", "dirty", "submit", "discard", "title",
    "previewHead", "previewRow", "previewHeadCell", "previewBodyCell",
  ]

  static values = {
    i18n: Object,
    sheet: Boolean,
    editing: String,
  }

  declare readonly formTarget: HTMLFormElement
  declare readonly listTarget: HTMLElement
  declare readonly blankTarget: HTMLTemplateElement
  declare readonly rowTargets: HTMLElement[]
  declare readonly summaryCountTarget: HTMLElement
  declare readonly summaryMaxTarget: HTMLElement
  declare readonly dirtyTarget: HTMLElement
  declare readonly hasDirtyTarget: boolean
  declare readonly submitTarget: HTMLButtonElement
  declare readonly discardTarget: HTMLDialogElement
  declare readonly previewHeadTarget: HTMLElement
  declare readonly previewRowTargets: HTMLElement[]
  declare readonly previewHeadCellTarget: HTMLTemplateElement
  declare readonly previewBodyCellTarget: HTMLTemplateElement
  declare readonly i18nValue: Wording
  declare readonly sheetValue: boolean
  declare readonly editingValue: string

  private destination = ""
  private pristine = ""

  connect() {
    this.hideRemovedRows()
    this.renumber()
    this.pristine = this.signature
    this.refresh()
  }

  refresh() {
    this.renumber()
    this.paintRows()
    this.paintPreview()
    this.paintSummary()
    this.paintDirty()
  }

  add(event: Event) {
    event.preventDefault()

    const markup = this.blankTarget.innerHTML.replace(/NEW_RECORD/g, String(Date.now()))
    const holder = document.createElement("div")

    holder.innerHTML = `<ul>${markup}</ul>`
    const row = holder.querySelector("li")

    if (!row) return

    this.listTarget.appendChild(row)
    this.refresh()
    row.querySelector<HTMLInputElement>("[data-sheet-form-target='name']")?.focus()
  }

  remove(event: Event) {
    const box = event.target as HTMLInputElement
    const row = box.closest<HTMLElement>("li")

    if (row) row.hidden = box.checked
    this.refresh()
  }

  moveUp(event: Event) {
    this.move(event, -1)
  }

  moveDown(event: Event) {
    this.move(event, 1)
  }

  leave(event: Event) {
    if (!this.dirty) return

    event.preventDefault()
    this.destination = (event.currentTarget as HTMLAnchorElement).href
    this.discardTarget.showModal()
  }

  discard() {
    this.discardTarget.close()
    window.location.href = this.destination
  }

  closeDiscard() {
    this.discardTarget.close()
  }

  closeOnBackdrop(event: MouseEvent) {
    if (event.target !== event.currentTarget) return

    this.discardTarget.close()
  }

  private hideRemovedRows() {
    this.rowTargets.forEach((row) => {
      if (this.destroyBox(row)?.checked) row.hidden = true
    })
  }

  private paintRows() {
    this.rowTargets.forEach((row) => {
      const hidden = this.hideBox(row)?.checked ?? false

      row.classList.toggle("gh-category-row--hidden", hidden)

      const tag = row.querySelector<HTMLElement>("[data-sheet-form-target='hiddenTag']")
      if (tag) tag.hidden = !hidden

      const icon = row.querySelector<HTMLElement>("[data-sheet-form-target='hideIcon']")
      if (icon) {
        icon.classList.toggle("fa-eye", hidden)
        icon.classList.toggle("fa-eye-slash", !hidden)
      }

      const note = row.querySelector<HTMLElement>("[data-sheet-form-target='rewardNote']")
      const field = this.rewardField(row)
      if (note && field) {
        const awarded = field.dataset.ghAwarded
        note.hidden = awarded === undefined || awarded === field.value
      }
    })
  }

  private paintPreview() {
    const columns = this.liveRows.filter((row) => !(this.hideBox(row)?.checked ?? false))

    this.trim(this.previewHeadTarget)
    this.previewRowTargets.forEach((row) => this.trim(row))

    columns.forEach((row) => {
      const head = this.previewHeadCellTarget.content.cloneNode(true) as DocumentFragment
      const name = this.nameField(row)?.value.trim()

      const label = head.querySelector(".gh-grading-column-name")
      if (label) label.textContent = name || "…"

      const cost = head.querySelector(".gh-price-badge b")
      if (cost) cost.textContent = `+${this.reward(row)}`

      this.previewHeadTarget.appendChild(head)

      this.previewRowTargets.forEach((previewRow) => {
        previewRow.appendChild(this.previewBodyCellTarget.content.cloneNode(true))
      })
    })
  }

  private paintSummary() {
    const columns = this.liveRows.filter((row) => !(this.hideBox(row)?.checked ?? false))
    const count = columns.length
    const max = columns.reduce((total, row) => total + this.reward(row), 0)

    this.summaryCountTarget.textContent = pluralize(this.i18nValue.columns, count)
    this.summaryMaxTarget.textContent = String(max)
  }

  private paintDirty() {
    if (!this.hasDirtyTarget) return

    const dirty = this.dirty

    this.dirtyTarget.textContent = dirty ? this.i18nValue.dirty : this.i18nValue.clean
    this.submitTarget.disabled = !dirty
  }

  private renumber() {
    let number = 0

    this.liveRows.forEach((row) => {
      number += 1

      const position = row.querySelector<HTMLInputElement>("[data-sheet-form-target='position']")
      if (position) position.value = String(number - 1)

      const t = this.i18nValue

      this.relabel(row, "name", interpolate(t.name_label, { number }))
      this.relabel(row, "reward", interpolate(t.reward_label, { number }))
      this.relabel(row, "destroy", interpolate(this.sheetValue ? t.destroy_column : t.destroy_category, { number }))

      const story = row.querySelector<HTMLElement>("textarea")
      story?.setAttribute("aria-label", interpolate(t.story_label, { number }))
    })

    const rows = this.liveRows
    rows.forEach((row, index) => {
      this.button(row, "up").disabled = index === 0
      this.button(row, "down").disabled = index === rows.length - 1
    })
  }

  private move(event: Event, direction: number) {
    const row = (event.currentTarget as HTMLElement).closest<HTMLElement>("li")
    if (!row) return

    const rows = this.liveRows
    const target = rows[rows.indexOf(row) + direction]
    if (!target) return

    if (direction < 0) target.before(row)
    else target.after(row)

    this.refresh()

    this.button(row, direction < 0 ? "up" : "down").focus()
  }

  private get liveRows(): HTMLElement[] {
    return this.rowTargets.filter((row) => !row.hidden)
  }

  private get dirty(): boolean {
    return this.signature !== this.pristine
  }

  private get signature(): string {
    return Array.from(new FormData(this.formTarget).entries())
      .map(([key, value]) => `${key}=${String(value)}`)
      .join("&")
  }

  private trim(row: HTMLElement) {
    while (row.children.length > 1) row.lastElementChild?.remove()
  }

  private relabel(row: HTMLElement, target: string, label: string) {
    row.querySelector(`[data-sheet-form-target='${target}']`)?.setAttribute("aria-label", label)
  }

  private button(row: HTMLElement, target: string): HTMLButtonElement {
    return row.querySelector(`[data-sheet-form-target='${target}']`) as HTMLButtonElement
  }

  private nameField(row: HTMLElement) {
    return row.querySelector<HTMLInputElement>("[data-sheet-form-target='name']")
  }

  private rewardField(row: HTMLElement) {
    return row.querySelector<HTMLInputElement>("[data-sheet-form-target='reward']")
  }

  private hideBox(row: HTMLElement) {
    return row.querySelector<HTMLInputElement>("input[data-sheet-form-target='hide']")
  }

  private destroyBox(row: HTMLElement) {
    return row.querySelector<HTMLInputElement>("input[data-sheet-form-target='destroy']")
  }

  private reward(row: HTMLElement): number {
    const parsed = Number.parseInt(this.rewardField(row)?.value ?? "", 10)

    return Number.isFinite(parsed) && parsed > 0 ? parsed : 0
  }
}

application.register("sheet-form", SheetFormController)
