import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

const ACTIVE_CLASS = "gh-file-dropzone--active"
const FILLED_CLASS = "gh-file-dropzone--filled"

class FileDropzoneController extends Controller<HTMLElement> {
  static targets = ["input", "icon", "title", "remove"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly iconTarget: HTMLElement
  declare readonly titleTarget: HTMLElement
  declare readonly hasTitleTarget: boolean
  declare readonly removeTarget: HTMLElement

  private defaultTitle = ""

  connect() {
    if (this.hasTitleTarget) this.defaultTitle = this.titleTarget.textContent ?? ""
  }

  show(event: Event) {
    const input = event.target as HTMLInputElement
    this.updateState(input.files?.[0])
  }

  clear(event: Event) {
    event.preventDefault()
    this.inputTarget.value = ""
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  dragOver(event: DragEvent) {
    event.preventDefault()
    this.element.classList.add(ACTIVE_CLASS)
  }

  dragLeave() {
    this.element.classList.remove(ACTIVE_CLASS)
  }

  drop(event: DragEvent) {
    event.preventDefault()
    this.element.classList.remove(ACTIVE_CLASS)

    const file = event.dataTransfer?.files?.[0]
    if (!file) return

    this.inputTarget.files = event.dataTransfer!.files
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  private updateState(file: File | undefined) {
    if (this.hasTitleTarget) this.titleTarget.textContent = file ? file.name : this.defaultTitle

    this.iconTarget.classList.toggle("fa-upload", !file)
    this.iconTarget.classList.toggle("fa-file-circle-check", Boolean(file))
    this.removeTarget.hidden = !file
    this.element.classList.toggle(FILLED_CLASS, Boolean(file))
  }
}

application.register("file-dropzone", FileDropzoneController)
