import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

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
