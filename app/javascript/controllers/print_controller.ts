import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

const PRINTING_CLASS = "gh-printing"
const ROOT_CLASS = "gh-print-root"

class PrintController extends Controller<HTMLElement> {
  static targets = ["sheet"]
  static values = { title: String }

  declare readonly sheetTarget: HTMLElement
  declare readonly hasSheetTarget: boolean
  declare readonly titleValue: string
  declare readonly hasTitleValue: boolean

  private originalTitle: string | null = null

  disconnect() {
    this.reset()
  }

  print() {
    if (!this.hasSheetTarget) return

    this.reset()

    const root = document.createElement("div")
    root.className = ROOT_CLASS
    root.innerHTML = this.sheetTarget.innerHTML

    this.originalTitle = document.title
    if (this.hasTitleValue) document.title = this.titleValue

    window.addEventListener("afterprint", () => this.reset(), { once: true })
    document.body.append(root)
    document.documentElement.classList.add(PRINTING_CLASS)
    window.print()
  }

  private reset() {
    document.querySelectorAll(`.${ROOT_CLASS}`).forEach((root) => root.remove())
    document.documentElement.classList.remove(PRINTING_CLASS)

    if (this.originalTitle !== null) {
      document.title = this.originalTitle
      this.originalTitle = null
    }
  }
}

application.register("print", PrintController)
