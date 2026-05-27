import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class CollapseMemoryController extends Controller {
  static values = { key: String }

  declare readonly keyValue: string

  connect() {
    const savedId = localStorage.getItem(this.keyValue)
    if (savedId) {
      const el = document.getElementById(savedId)
      if (el) el.classList.add("show")
    }

    this.element.addEventListener("show.bs.collapse", this.onShow)
    this.element.addEventListener("hide.bs.collapse", this.onHide)
  }

  disconnect() {
    this.element.removeEventListener("show.bs.collapse", this.onShow)
    this.element.removeEventListener("hide.bs.collapse", this.onHide)
  }

  private onShow = (e: Event) => {
    localStorage.setItem(this.keyValue, (e.target as Element).id)
  }

  private onHide = (e: Event) => {
    if (localStorage.getItem(this.keyValue) === (e.target as Element).id) {
      localStorage.removeItem(this.keyValue)
    }
  }
}

application.register("collapse-memory", CollapseMemoryController)
