import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Instant filtering of the group grid ("Grupy", mockup `vIndex`).
 *
 * Client-side on purpose: a user's groups are all on the page already, so
 * matching them costs nothing and the list narrows as you type, exactly as the
 * mockup does. The filter tabs stay server-side — those change what is loaded,
 * this only hides what is loaded — so the tab counts deliberately do not react
 * to the query.
 */
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
