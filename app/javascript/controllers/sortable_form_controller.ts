import { Controller } from "@hotwired/stimulus"
import { application } from "@controllers/application"
import Sortable from "sortablejs"

class SortableFormController extends Controller {
  static targets = ["list", "item", "position", "destroy", "categoryTemplate", "templateSelect"]
  static values = {
    handle: String,
    templatesUrl: String,
    modelName: String,
    association: String,
  }

  declare readonly listTarget: HTMLElement
  declare readonly itemTargets: HTMLElement[]
  declare readonly hasCategoryTemplateTarget: boolean
  declare readonly categoryTemplateTarget: HTMLTemplateElement
  declare readonly hasTemplateSelectTarget: boolean
  declare readonly templateSelectTarget: HTMLSelectElement
  declare handleValue: string
  declare templatesUrlValue: string
  declare modelNameValue: string
  declare associationValue: string

  private sortable: Sortable | null = null
  private newItemIndex: number = 0

  connect() {
    this.newItemIndex = this.itemTargets.length

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

  addCategory(event: Event) {
    event.preventDefault()
    this.insertCategory({})
  }

  async addFromTemplate(event: Event) {
    event.preventDefault()

    if (!this.hasTemplateSelectTarget) return
    const templateId = this.templateSelectTarget.value
    if (!templateId) return

    try {
      const url = `${this.templatesUrlValue}/${templateId}.json`
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) return

      const template = await response.json()
      template.categories.forEach((cat: any) => this.insertCategory(cat))
    } catch {
      alert("Failed to load template categories. Please try again.")
    }
  }

  removeCategory(event: Event) {
    event.preventDefault()

    const item = (event.target as HTMLElement).closest("[data-sortable-form-target='item']") as HTMLElement
    if (!item) return

    const hasIdInput = item.querySelector("input[name*='[id]']")
    const destroyInput = item.querySelector("[data-sortable-form-target='destroy']") as HTMLInputElement

    if (hasIdInput) {
      destroyInput.value = "true"
      item.style.display = "none"
    } else {
      item.remove()
    }

    this.updatePositions()
  }

  private insertCategory(data: { story_description?: string; didactic_description?: string; reward?: number }) {
    const timestamp = new Date().getTime() + this.newItemIndex
    const clone = this.buildClone(timestamp)

    if (data.story_description != null) {
      const ta = clone.querySelector("textarea[name*='story_description']") as HTMLTextAreaElement
      if (ta) ta.value = data.story_description
    }
    if (data.didactic_description != null) {
      const ta = clone.querySelector("textarea[name*='didactic_description']") as HTMLTextAreaElement
      if (ta) ta.value = data.didactic_description
    }
    if (data.reward != null) {
      const input = clone.querySelector("input[name*='reward']") as HTMLInputElement
      if (input) input.value = String(data.reward)
    }

    this.listTarget.appendChild(clone)
    this.newItemIndex++
    this.updatePositions()
  }

  private buildClone(timestamp: number): HTMLElement {
    if (this.hasCategoryTemplateTarget) {
      const fragment = this.categoryTemplateTarget.content.cloneNode(true) as DocumentFragment
      const clone = fragment.querySelector(".category-fields") as HTMLElement
      clone.querySelectorAll("input, textarea, select").forEach((el) => {
        const input = el as HTMLInputElement
        input.name = input.name.replaceAll("NEW_RECORD", String(timestamp))
        input.id = input.id.replaceAll("NEW_RECORD", String(timestamp))
        input.value = ""
      })
      const destroyInput = clone.querySelector("[data-sortable-form-target='destroy']") as HTMLInputElement
      if (destroyInput) destroyInput.value = "false"
      return clone
    }

    // Fallback: clone existing item from list
    const existingItem = this.listTarget.querySelector(".category-fields") as HTMLElement | null
    if (existingItem) {
      const clone = existingItem.cloneNode(true) as HTMLElement
      clone.querySelectorAll("input, textarea, select").forEach((el) => {
        const input = el as HTMLInputElement
        input.name = input.name.replace(/(_attributes\])\[\d+\]/, `$1[${timestamp}]`)
        input.id = input.id.replace(/_attributes_\d+_/, `_attributes_${timestamp}_`)
        input.value = ""
      })
      const destroyInput = clone.querySelector("[data-sortable-form-target='destroy']") as HTMLInputElement
      if (destroyInput) destroyInput.value = "false"
      return clone
    }

    return this.buildCategoryElement(timestamp)
  }

  private buildCategoryElement(timestamp: number): HTMLElement {
    const modelName = this.modelNameValue
    const association = this.associationValue
    const prefix = `${modelName}[${association}_attributes][${timestamp}]`

    const div = document.createElement("div")
    div.className = "category-fields"
    div.setAttribute("data-sortable-form-target", "item")
    div.innerHTML = `
      <span class="drag-handle">☰</span>
      <input type="hidden" name="${prefix}[position]" data-sortable-form-target="position">
      <input type="hidden" name="${prefix}[_destroy]" value="false" data-sortable-form-target="destroy">
      <div>
        <label>Story description</label>
        <textarea name="${prefix}[story_description]"></textarea>
      </div>
      <div>
        <label>Didactic description</label>
        <textarea name="${prefix}[didactic_description]"></textarea>
      </div>
      <div>
        <label>Reward</label>
        <input type="number" name="${prefix}[reward]" value="">
      </div>
      <a href="#" data-action="click->sortable-form#removeCategory">Remove</a>
      <hr>
    `
    return div
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
