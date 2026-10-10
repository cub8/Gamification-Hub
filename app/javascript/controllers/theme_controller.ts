import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

type Theme = "light" | "dark"

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
