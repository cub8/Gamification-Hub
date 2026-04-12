import { Controller } from "@hotwired/stimulus"
import { application } from "@controllers/application"

class TemplateLoaderController extends Controller {
  static targets = ["select"]
  static values = {
    url: String,
    association: String,
  }

  declare readonly selectTarget: HTMLSelectElement
  declare urlValue: string
  declare associationValue: string

  async loadTemplate(event: Event) {
    event.preventDefault()

    const templateId = this.selectTarget.value
    if (!templateId) return

    const templateEl = this.element.querySelector("template[data-nested-rondo-target='template']") as HTMLTemplateElement | null
    if (!templateEl) return

    try {
      const response = await fetch(`${this.urlValue}/${templateId}.json`, {
        headers: { Accept: "application/json" },
      })
      if (!response.ok) return

      const data = await response.json()
      const container = this.element.querySelector("[data-nested-rondo-target='fieldContain']") as HTMLElement
      if (!container) return

      const assoc = this.associationValue
      const regexp = new RegExp(`\\[new_${assoc}\\](.*?\\s)`, "g")

      data.categories.forEach((cat: any) => {
        const timestamp = new Date().getTime() + Math.floor(Math.random() * 1000)
        const wrapper = document.createElement("div")
        wrapper.innerHTML = templateEl.innerHTML.replace(regexp, `[${timestamp}]$1`)

        const fieldEl = wrapper.firstElementChild as HTMLElement | null
        if (!fieldEl) return

        fieldEl.classList.add("dynamic")

        if (cat.story_description) {
          const ta = fieldEl.querySelector("textarea[name*='story_description']") as HTMLTextAreaElement
          if (ta) ta.value = cat.story_description
        }
        if (cat.didactic_description) {
          const ta = fieldEl.querySelector("textarea[name*='didactic_description']") as HTMLTextAreaElement
          if (ta) ta.value = cat.didactic_description
        }
        if (cat.reward != null) {
          const inp = fieldEl.querySelector("input[name*='reward']") as HTMLInputElement
          if (inp) inp.value = String(cat.reward)
        }

        container.appendChild(fieldEl)
      })
    } catch {
      alert("Failed to load template categories. Please try again.")
    }
  }
}

application.register("template-loader", TemplateLoaderController)
