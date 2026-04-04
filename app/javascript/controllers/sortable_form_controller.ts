import { Controller } from "@hotwired/stimulus"
import { application } from "@controllers/application"
import Sortable from "sortablejs"

class SortableFormController extends Controller {
  static targets = ["list", "item", "position", "destroy"]
  static values = {
    handle: String,
  }

  declare readonly listTarget: HTMLElement
  declare readonly itemTargets: HTMLElement[]
  declare handleValue: string

  private sortable: Sortable | null = null

  connect() {
    this.sortable = Sortable.create(this.listTarget, {
      handle: this.handleValue || ".drag-handle",
      animation: 150,
      onStart: () => document.body.classList.add("sortable-dragging"),
      onEnd: () => {
        document.body.classList.remove("sortable-dragging")
        this.updatePositions()
      },
    })

    this.updatePositions()
  }

  disconnect() {
    this.sortable?.destroy()
    this.sortable = null
  }

  private updatePositions() {
    const visibleItems = this.itemTargets.filter((item) => item.style.display !== "none")
    visibleItems.forEach((item, index) => {
      const positionInput = item.querySelector("[data-sortable-form-target='position']") as HTMLInputElement
      if (positionInput) positionInput.value = String(index)
    })
  }
}

application.register("sortable-form", SortableFormController)
