import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class CompletionsController extends Controller {
  static values = { url: String }

  declare urlValue: string

  toggle(event: Event) {
    const checkbox = event.target as HTMLInputElement
    const studentId = checkbox.dataset.studentId!
    const categoryId = checkbox.dataset.categoryId!

    const body = new FormData()
    body.append("student_id", studentId)
    body.append("category_id", categoryId)
    body.append("completed", checkbox.checked ? "1" : "0")

    const csrfToken =
      (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)
        ?.content ?? ""

    fetch(this.urlValue, {
      method: "PATCH",
      headers: { "X-CSRF-Token": csrfToken },
      body,
    })
  }
}

application.register("completions", CompletionsController)
