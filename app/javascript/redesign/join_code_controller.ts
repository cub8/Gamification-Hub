import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The six-box invite code (mockup `dlgJoin`, js-expanded/10-core.js:400-424).
 *
 * The boxes are presentation: they carry no name, and the value the form
 * actually submits lives in one hidden field this controller keeps in sync. So
 * a code that arrives by paste, by autofill or by typing all reach the server
 * the same way, and the form still works if this controller never boots.
 */
class JoinCodeController extends Controller {
  static targets = ["slot", "code", "submit"]

  declare readonly slotTargets: HTMLInputElement[]
  declare readonly codeTarget: HTMLInputElement
  declare readonly submitTarget: HTMLButtonElement

  connect() {
    this.sync()
  }

  /** One character per box, uppercased, then move on. */
  type(event: Event) {
    const slot = event.target as HTMLInputElement

    slot.value = this.clean(slot.value).slice(-1)

    if (slot.value) this.slotAfter(slot)?.focus()

    this.sync()
  }

  key(event: KeyboardEvent) {
    const slot = event.target as HTMLInputElement

    // Backspace in an empty box steps back and clears the previous one, so
    // holding it walks the code backwards instead of stalling.
    if (event.key === "Backspace" && !slot.value) {
      const previous = this.slotBefore(slot)

      if (previous) {
        previous.value = ""
        previous.focus()
        event.preventDefault()
        this.sync()
      }
    }

    if (event.key === "Enter" && !this.submitTarget.disabled) {
      this.submitTarget.form?.requestSubmit()
    }
  }

  /** A pasted code fills every box at once, wherever it was dropped. */
  paste(event: ClipboardEvent) {
    event.preventDefault()

    const text = this.clean(event.clipboardData?.getData("text") ?? "").slice(0, this.slotTargets.length)

    this.slotTargets.forEach((slot, index) => {
      slot.value = text[index] ?? ""
    })

    const landing = Math.min(text.length, this.slotTargets.length - 1)

    this.slotTargets[landing]?.focus()
    this.sync()
  }

  private sync() {
    const code = this.slotTargets.map((slot) => slot.value).join("")

    this.codeTarget.value = code
    this.submitTarget.disabled = code.length < this.slotTargets.length
  }

  private clean(value: string): string {
    return value.toUpperCase().replace(/[^A-Z0-9]/g, "")
  }

  private slotAfter(slot: HTMLInputElement) {
    return this.slotTargets[this.slotTargets.indexOf(slot) + 1]
  }

  private slotBefore(slot: HTMLInputElement) {
    return this.slotTargets[this.slotTargets.indexOf(slot) - 1]
  }
}

application.register("join-code", JoinCodeController)
