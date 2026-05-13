import { Controller } from "@hotwired/stimulus"
import { application } from "@controllers/application"

class DesktopSidebarController extends Controller {
  static targets = ["full", "collapsed"]

  declare readonly fullTarget: HTMLElement
  declare readonly collapsedTarget: HTMLElement

  toggle() {
    const isCollapsed = this.fullTarget.classList.contains("d-none")

    if (isCollapsed) {
      this.fullTarget.classList.remove("d-none")
      this.collapsedTarget.classList.add("d-none")
      document.cookie = this.sidebarCookie("false")
    } else {
      this.fullTarget.classList.add("d-none")
      this.collapsedTarget.classList.remove("d-none")
      document.cookie = this.sidebarCookie("true")
    }
  }

  private sidebarCookie(value: string) {
    return `sidebar_collapsed=${value}; path=/; max-age=${this.cookieExpireTime}`
  }

  private get cookieExpireTime() {
    return 60 * 60 * 24 * 30
  }
}

application.register("desktop-sidebar", DesktopSidebarController)
