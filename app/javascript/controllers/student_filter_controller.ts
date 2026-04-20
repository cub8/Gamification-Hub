import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class StudentFilterController extends Controller {
  static targets = ["row", "button"]

  declare rowTargets: HTMLElement[]
  declare buttonTarget: HTMLElement

  private visible = false

  toggle() {
    this.visible = !this.visible
    this.rowTargets.forEach(row => { row.hidden = !this.visible })
    this.buttonTarget.textContent = this.visible ? "Hide students" : "Show students"
  }
}

application.register("student-filter", StudentFilterController)
