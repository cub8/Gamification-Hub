import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

type Theme = "light" | "dark"

/**
 * Light/dark switching for the redesign.
 *
 * Sets `data-gh-theme` on <html> and persists the choice in a cookie so the
 * server can render the attribute on the next request — without that, every
 * page load flashes the default theme before JS runs.
 *
 * The attribute is namespaced (`data-gh-theme`, not `data-theme`) so it cannot
 * be confused with another framework's theming while Bootstrap is still around.
 */
class ThemeController extends Controller {
  static values = { cookie: { type: String, default: "gh_theme" } }

  declare readonly cookieValue: string

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
  }

  private get current(): Theme {
    if (document.documentElement.getAttribute("data-gh-theme") === "dark") return "dark"
    if (document.documentElement.getAttribute("data-gh-theme") === "light") return "light"

    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }
}

application.register("theme", ThemeController)
