import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The lives stepper in "Edytuj studenta" (mockup 30-student.js:39).
 *
 * A stepper over a hidden field rather than a number input: the mockup's shape,
 * and it keeps the value at or above zero without a spinner nobody can hit on a
 * phone. The field is what posts; the <output> is what is read aloud.
 *
 * With JavaScript off the buttons do nothing and the hidden field still carries
 * the student's current number, so submitting changes nothing — which is the
 * right no-op for a form whose only control is this one.
 */
class LivesStepperController extends Controller<HTMLElement> {
  static targets = ["field", "output", "down", "submit"]
  static values = { start: Number }

  declare readonly fieldTarget: HTMLInputElement
  declare readonly outputTarget: HTMLOutputElement
  declare readonly downTarget: HTMLButtonElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly startValue: number

  connect() {
    this.render()
  }

  up() {
    this.write(this.lives + 1)
  }

  down() {
    this.write(Math.max(0, this.lives - 1))
  }

  private write(lives: number) {
    this.fieldTarget.value = String(lives)
    this.render()
  }

  /**
   * "Zapisz" is disabled while nothing has changed — pressing it would write
   * the number that is already there. The mockup does the same but also puts
   * the initial focus on that disabled button; focus lives on the stepper here
   * instead.
   */
  private render() {
    const lives = this.lives

    this.outputTarget.textContent = String(lives)
    this.downTarget.disabled = lives === 0
    this.submitTarget.disabled = lives === this.startValue
  }

  private get lives(): number {
    const parsed = Number.parseInt(this.fieldTarget.value, 10)

    return Number.isFinite(parsed) && parsed > 0 ? parsed : 0
  }
}

application.register("lives-stepper", LivesStepperController)
