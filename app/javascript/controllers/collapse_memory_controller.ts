import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class CollapseMemoryController extends Controller {
  static values = { key: String }

  declare readonly keyValue: string

  connect() {
    this.element.addEventListener("show.bs.collapse", this.onShow)
    this.element.addEventListener("hide.bs.collapse", this.onHide)
  }

  disconnect() {
    this.element.removeEventListener("show.bs.collapse", this.onShow)
    this.element.removeEventListener("hide.bs.collapse", this.onHide)
  }

  private onShow = (e: Event) => {
    document.cookie = `${this.keyValue}=${(e.target as Element).id}; path=/; max-age=${60 * 60 * 24 * 30}`
  }

  private onHide = (e: Event) => {
    if (this.cookieValue() === (e.target as Element).id) {
      document.cookie = `${this.keyValue}=; path=/; max-age=0`
    }
  }

  private cookieValue(): string {
    const match = document.cookie.match(new RegExp(`(?:^|; )${this.keyValue}=([^;]*)`))
    return match ? decodeURIComponent(match[1]) : ""
  }
}

application.register("collapse-memory", CollapseMemoryController)
