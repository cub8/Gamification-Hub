import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The template editor and sheet settings — mockup js-expanded/30-ag.js:42-95.
 *
 * Everything this controller does, the screen also does without it, with one
 * exception: reordering. Rows are server-rendered, removal and hiding are
 * checkboxes that post on their own, and the story description is a <details>.
 * What is left here is the live preview, the running summary, the dirty
 * marker, the ordering, and the guard on leaving with unsaved changes.
 *
 * It never writes markup. New rows and preview columns are clones of two
 * <template>s the server rendered; everything else is `hidden` and text.
 */
class SheetFormController extends Controller<HTMLElement> {
  static targets = [
    "form", "list", "blank", "row", "position", "name", "reward", "hide", "destroy",
    "hideIcon", "hiddenTag", "rewardNote", "up", "down",
    "summaryCount", "summaryMax", "dirty", "submit", "discard", "title",
    "previewHead", "previewRow", "previewHeadCell", "previewBodyCell",
  ]

  static values = {
    columns: Array,
    currency: String,
    categoryLabel: String,
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
  declare readonly columnsValue: string[]
  declare readonly currencyValue: string
  declare readonly categoryLabelValue: string
  declare readonly editingValue: string

  /** Where "Odrzuć zmiany" goes once the teacher confirms. */
  private destination = ""
  private pristine = ""

  connect() {
    // Normalise BEFORE the snapshot. Renumbering positions is housekeeping,
    // not an edit, and a sheet whose saved positions have a gap in them would
    // otherwise report itself as dirty the moment the page loaded.
    this.hideRemovedRows()
    this.renumber()
    this.pristine = this.signature
    this.refresh()
  }

  /** Any input, any reorder, any checkbox. One entry point, as the mockup has. */
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

    // A <li> cannot be parsed loose, so it travels via a container and is
    // moved, not copied, into the list.
    holder.innerHTML = `<ul>${markup}</ul>`
    const row = holder.querySelector("li")

    if (!row) return

    this.listTarget.appendChild(row)
    this.refresh()
    row.querySelector<HTMLInputElement>("[data-sheet-form-target='name']")?.focus()
  }

  /**
   * Removal is pending until save, exactly as the mockup has it: the row's
   * `_destroy` box is now ticked and the row goes out of sight, but nothing
   * has happened to the record yet.
   */
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

  /**
   * Intercepts Anuluj and the crumb link while there is something to lose.
   * With nothing to lose it is an ordinary link.
   */
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

  // --- painting ------------------------------------------------------------

  /** Rows the server rendered as already marked for destruction. */
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

      // "Nowa wartość obejmie tylko przyszłe nagrody." — only once the number
      // differs from the one that already paid out.
      const note = row.querySelector<HTMLElement>("[data-sheet-form-target='rewardNote']")
      const field = this.rewardField(row)
      if (note && field) {
        const awarded = field.dataset.ghAwarded
        note.hidden = awarded === undefined || awarded === field.value
      }
    })
  }

  /**
   * The preview is rebuilt rather than patched: a column can appear, vanish,
   * move or be hidden, and rebuilding from two <template>s is both shorter and
   * harder to get wrong than reconciling four cases.
   */
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

    this.summaryCountTarget.textContent = `${count} ${plural(count, this.columnsValue)}`
    this.summaryMaxTarget.textContent = String(max)
  }

  private paintDirty() {
    if (!this.hasDirtyTarget) return

    const dirty = this.dirty

    this.dirtyTarget.textContent = dirty ? "Niezapisane zmiany" : "Brak zmian"
    this.submitTarget.disabled = !dirty
  }

  /**
   * Row numbering is in the aria labels only — "Kategoria 3: za co" — so it has
   * to follow the list as rows come and go. The position fields are renumbered
   * at the same time, skipping removed rows so the server gets 0..n-1.
   */
  private renumber() {
    let number = 0

    this.liveRows.forEach((row) => {
      number += 1

      const position = row.querySelector<HTMLInputElement>("[data-sheet-form-target='position']")
      if (position) position.value = String(number - 1)

      this.relabel(row, "name", `Kategoria ${number}: za co`)
      this.relabel(row, "reward", `Nagroda za kategorię ${number}`)
      this.relabel(row, "destroy", `Usuń ${this.categoryLabelValue} ${number}`)

      const story = row.querySelector<HTMLElement>("textarea")
      story?.setAttribute("aria-label", `Opis fabularny kategorii ${number}`)
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

    // Follow the row, or focus lands on whatever slid into its place.
    this.button(row, direction < 0 ? "up" : "down").focus()
  }

  // --- reading the DOM -----------------------------------------------------

  private get liveRows(): HTMLElement[] {
    return this.rowTargets.filter((row) => !row.hidden)
  }

  private get dirty(): boolean {
    return this.signature !== this.pristine
  }

  /** Every posted value in one string. Cheap, and exact about what will save. */
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

/** Polish plurals: one / few / many, the same split as Plural. */
function plural(count: number, forms: string[]): string {
  const [one, few, many] = forms
  const last = count % 10
  const teens = count % 100

  if (count === 1) return one
  if (last >= 2 && last <= 4 && (teens < 12 || teens > 14)) return few

  return many
}

application.register("sheet-form", SheetFormController)
