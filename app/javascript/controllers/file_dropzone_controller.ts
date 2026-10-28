import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

const ACTIVE_CLASS = "gh-file-dropzone--active"

class FileDropzoneController extends Controller<HTMLElement> {
  static targets = ["input", "hint"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly hintTarget: HTMLElement
  declare readonly hasHintTarget: boolean

  private defaultHint = ""

  connect() {
    if (this.hasHintTarget) this.defaultHint = this.hintTarget.textContent ?? ""
  }

  show(event: Event) {
    const input = event.target as HTMLInputElement
    this.updateHint(input.files?.[0])
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
    this.updateHint(file)
  }

  private updateHint(file: File | undefined) {
    if (!this.hasHintTarget) return

    this.hintTarget.textContent = file ? `Wybrano: ${file.name}` : this.defaultHint
  }
}

application.register("file-dropzone", FileDropzoneController)
