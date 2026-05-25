import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class FileUploadController extends Controller {
  static targets = ["input", "fileName"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly fileNameTarget: HTMLSpanElement

  update() {
    const files = this.inputTarget.files as FileList
    const file = files[0]

    if (file) {
      const textContainer = this.fileNameTarget.querySelector(".uploaded-file-name")
      if (textContainer) textContainer.textContent = file.name
      this.fileNameTarget.classList.remove("d-none")
    }
  }
}

application.register("file-upload", FileUploadController)
