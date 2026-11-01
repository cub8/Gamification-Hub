import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class ForbiddenCharsController extends Controller<HTMLElement> {
  static targets = ["input", "hint"]
  static values = { chars: String }

  declare readonly inputTarget: HTMLInputElement
  declare readonly hintTarget: HTMLElement
  declare readonly charsValue: string

  connect() {
    this.hintTarget.hidden = true
  }

  strip() {
    const input = this.inputTarget
    const original = input.value
    const cleaned = this.clean(original)
    const removed = cleaned !== original

    if (removed) {
      const caret = this.clean(original.slice(0, input.selectionStart ?? original.length)).length

      input.value = cleaned
      input.setSelectionRange(caret, caret)
    }

    this.hintTarget.hidden = !removed
  }

  private clean(text: string): string {
    const forbidden = new Set(Array.from(this.charsValue))

    return Array.from(text).filter((char) => !forbidden.has(char)).join("")
  }
}

application.register("forbidden-chars", ForbiddenCharsController)
