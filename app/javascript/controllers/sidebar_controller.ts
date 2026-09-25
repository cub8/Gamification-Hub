import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Desktop sidebar collapse.
 *
 * Writes the same `sidebar_collapsed` cookie the Bootstrap layout already uses
 * (ApplicationController#set_sidebar_state), so the preference carries across
 * both layouts while the migration is in progress, and the server renders the
 * collapsed state on first paint instead of it snapping after JS boots.
 *
 * Collapse is a user choice only — never breakpoint-driven. Below 720px the
 * sidebar is hidden entirely and the tab bar takes over.
 */
class SidebarController extends Controller {
  static targets = ["sidebar", "label", "icon"]
  static values = {
    cookie: { type: String, default: "sidebar_collapsed" },
    expandLabel: { type: String, default: "Rozwiń" },
    collapseLabel: { type: String, default: "Zwiń panel" },
  }

  declare readonly sidebarTarget: HTMLElement
  declare readonly labelTarget: HTMLElement
  declare readonly iconTarget: HTMLElement
  declare readonly cookieValue: string
  declare readonly expandLabelValue: string
  declare readonly collapseLabelValue: string

  toggle() {
    const collapsed = this.sidebarTarget.classList.toggle("gh-sidebar--collapsed")

    document.cookie = `${this.cookieValue}=${collapsed};path=/;max-age=31536000;samesite=lax`

    this.labelTarget.textContent = collapsed ? this.expandLabelValue : this.collapseLabelValue
    this.iconTarget.classList.toggle("fa-angles-right", collapsed)
    this.iconTarget.classList.toggle("fa-angles-left", !collapsed)

    const button = this.element.querySelector("[data-action~='sidebar#toggle']")

    button?.setAttribute("aria-expanded", String(!collapsed))
  }
}

application.register("sidebar", SidebarController)
