import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class GroupSearchController extends Controller {
  static targets = ["input", "card", "empty", "emptyQuery"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly cardTargets: HTMLElement[]
  declare readonly emptyTarget: HTMLElement
  declare readonly emptyQueryTarget: HTMLElement

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()

    const matches = this.cardTargets.filter((card) => {
      const name = card.dataset.groupSearchName ?? ""
      const hit = name.includes(query)

      card.hidden = !hit

      return hit
    })

    this.emptyQueryTarget.textContent = `„${this.inputTarget.value.trim()}”`
    this.emptyTarget.hidden = matches.length > 0
  }
}

application.register("group-search", GroupSearchController)
