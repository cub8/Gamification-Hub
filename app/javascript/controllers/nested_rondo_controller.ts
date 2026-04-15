import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class NestedRondoController extends Controller {
  static targets = ["template", "fieldContain"]
  static values = {
    fieldClass: String,
  }

  declare readonly fieldClassValue: string
  declare readonly hasFieldClassValue: boolean
  declare readonly templateTarget: HTMLTemplateElement
  declare readonly fieldContainTarget: HTMLDivElement

  addField(e: MouseEvent) {
    e.preventDefault()
    const newField = this.buildNewAssociation(e)
    this.fieldContainTarget.insertAdjacentHTML("beforeend", newField)
  }

  removeField(e: MouseEvent) {
    e.preventDefault()
    const target = e.target as HTMLElement
    const wrapperField = this.hasFieldClassValue ?
      target.closest(`.${this.fieldClassValue}`) as HTMLElement | null :
      target.parentNode as HTMLElement | null

    if (!wrapperField) return

    if (target.matches(".dynamic")) {
      wrapperField.remove()
    } else {
      const inputField = wrapperField.querySelector("input[name*='_destroy']") as HTMLInputElement
      inputField.value = "1"
      wrapperField.style.display = "none"
    }
  }

  buildNewAssociation(event: MouseEvent) {
    let element = event.target as HTMLElement

    while (element) {
      if (element.hasAttribute("data-association") || element.hasAttribute("data-associations")) break
      element = element.parentElement as HTMLElement
    }
    const assoc = element.dataset.association
    const assocs = element.dataset.associations
    const content = this.templateTarget.innerHTML

    let regexpBraced = new RegExp(`\\[new_${assoc}\\](.*?\\s)`, "g")
    let newId = new Date().getTime()
    let newContent = content.replace(regexpBraced, `[${newId}]$1`)

    if (newContent == content) {
      // assoc can be singular or plural
      regexpBraced = new RegExp(`\\[new_${assocs}\\](.*?\\s)`, "g")
      newContent = content.replace(regexpBraced, `[${newId}]$1`)
    }
    return newContent
  }
}

application.register("nested-rondo", NestedRondoController)
