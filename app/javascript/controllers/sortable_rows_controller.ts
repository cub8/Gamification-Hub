import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

/**
 * Drag-to-reorder over a list of nested-attribute rows.
 *
 * The legacy bundle has `sortable_form_controller`, but it registers into the
 * other Stimulus application and reads targets this markup does not have, so
 * this is a separate file rather than a shared one — the two bundles have no
 * runtime in common.
 *
 * Positions live in a hidden field per row and are renumbered after every
 * drop. Rows the teacher removed are still in the DOM (hidden, carrying
 * `_destroy`), so they are skipped rather than counted: numbering them would
 * leave gaps the server then has to interpret.
 *
 * Reordering is the one thing on these screens that genuinely needs
 * JavaScript. The up/down buttons beside each row are the keyboard path, and
 * they live in sheet_form — this controller only owns the pointer.
 */
class SortableRowsController extends Controller<HTMLElement> {
  static values = { handle: { type: String, default: ".gh-category-drag-handle" } }

  declare readonly handleValue: string

  private sortable: Sortable | null = null

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: this.handleValue,
      animation: 150,
      draggable: "li",
      ghostClass: "gh-category-row--drop-target",
      dragClass: "gh-category-row--dragging",
      onEnd: () => {
        this.renumber()
        this.dispatch("reordered")
      },
    })
  }

  disconnect() {
    this.sortable?.destroy()
    this.sortable = null
  }

  /** Exposed so sheet_form can call it after an add, a remove or a move. */
  renumber() {
    let position = 0

    Array.from(this.element.children).forEach((row) => {
      const field = row.querySelector<HTMLInputElement>("[data-sheet-form-target='position']")

      if (!field) return
      if ((row as HTMLElement).hidden) return

      field.value = String(position)
      position += 1
    })
  }
}

application.register("sortable-rows", SortableRowsController)
