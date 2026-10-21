import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class CsvExportController extends Controller<HTMLFormElement> {
  static targets = ["checkbox", "submit"]
  static values = { baseUrl: String }

  declare readonly checkboxTargets: HTMLInputElement[]
  declare readonly submitTarget: HTMLButtonElement
  declare readonly baseUrlValue: string

  connect() {
    this.refresh()
  }

  refresh() {
    this.submitTarget.disabled = this.selectedCheckboxes.length === 0
  }

  download(event: Event) {
    const selected = this.selectedCheckboxes

    if (selected.length === 0) return

    event.preventDefault()

    selected.forEach((checkbox, index) => {
      window.setTimeout(() => this.triggerDownload(checkbox.dataset.resource ?? ""), index * 150)
    })
  }

  private get selectedCheckboxes(): HTMLInputElement[] {
    return this.checkboxTargets.filter((checkbox) => checkbox.checked)
  }

  private triggerDownload(resource: string) {
    const link = document.createElement("a")

    link.href = `${this.baseUrlValue}?resource=${encodeURIComponent(resource)}`
    link.rel = "noopener"
    document.body.appendChild(link)
    link.click()
    link.remove()
  }
}

application.register("csv-export", CsvExportController)
