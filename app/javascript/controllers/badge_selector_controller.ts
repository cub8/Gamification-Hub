import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class BadgeSelectorController extends Controller {
  static targets = ["input", "badge", "select"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly badgeTargets: HTMLElement[]
  declare readonly selectTarget: HTMLSelectElement

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    this.badgeTargets.forEach((badge) => {
      const name = badge.dataset.badgeName?.toLowerCase() ?? ""
      badge.hidden = query.length > 0 && !name.includes(query)
    })
  }

  select(event: MouseEvent) {
    const badge = event.currentTarget as HTMLElement
    const id = badge.dataset.badgeId

    if (badge.classList.contains("selected")) {
      badge.classList.remove("selected")
      this.selectTarget.value = ""
    } else {
      this.badgeTargets.forEach((b) => b.classList.remove("selected"))
      badge.classList.add("selected")
      this.selectTarget.value = id ?? ""
    }
  }
}

application.register("badge-selector", BadgeSelectorController)
