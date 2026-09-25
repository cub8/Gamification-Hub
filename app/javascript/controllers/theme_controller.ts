import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

type Theme = "light" | "dark"

/**
 * Light/dark switching for the app.
 *
 * Sets `data-gh-theme` on <html> and persists the choice in a cookie so the
 * server can render the attribute on the next request — without that, every
 * page load flashes the default theme before JS runs.
 *
 * The attribute is namespaced (`data-gh-theme`, not `data-theme`) so it cannot
 * be confused with another framework's theming while Bootstrap is still around.
 *
 * The label names the theme you would switch TO, matching the mockup. Both
 * labels come from the view so the Polish copy stays in the template.
 */
class ThemeController extends Controller {
  static targets = ["label"]
  static values = {
    cookie: { type: String, default: "gh_theme" },
    lightLabel: { type: String, default: "Jasny motyw" },
    darkLabel: { type: String, default: "Ciemny motyw" },
  }

  declare readonly cookieValue: string
  declare readonly lightLabelValue: string
  declare readonly darkLabelValue: string
  declare readonly labelTargets: HTMLElement[]

  toggle() {
    this.apply(this.current === "dark" ? "light" : "dark")
  }

  set(event: Event) {
    const theme = (event.currentTarget as HTMLElement).dataset.theme

    if (theme === "light" || theme === "dark") this.apply(theme)
  }

  private apply(theme: Theme) {
    document.documentElement.setAttribute("data-gh-theme", theme)
    document.cookie = `${this.cookieValue}=${theme};path=/;max-age=31536000;samesite=lax`

    // Plural: the chrome shows the toggle in the header, the account menu and
    // the "Więcej" sheet at once, and all of them must agree.
    const label = theme === "dark" ? this.lightLabelValue : this.darkLabelValue

    this.labelTargets.forEach((element) => (element.textContent = label))
  }

  private get current(): Theme {
    if (document.documentElement.getAttribute("data-gh-theme") === "dark") return "dark"
    if (document.documentElement.getAttribute("data-gh-theme") === "light") return "light"

    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }
}

application.register("theme", ThemeController)
