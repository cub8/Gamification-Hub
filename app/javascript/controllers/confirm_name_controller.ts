import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class ConfirmNameController extends Controller<HTMLFormElement> {
  static targets = ["input", "submit"]
  static values = { expected: String }

  declare readonly inputTarget: HTMLInputElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly expectedValue: string

  connect() {
    this.check()
  }

  check() {
    this.submitTarget.disabled = this.inputTarget.value.trim() !== this.expectedValue
  }
}

application.register("confirm-name", ConfirmNameController)
