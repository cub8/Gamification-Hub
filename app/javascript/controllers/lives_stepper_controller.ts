import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The lives stepper — "Edytuj studenta" (mockup 30-student.js:39) and "Życia na
 * start" in group settings (30-isg.js:57).
 *
 * A stepper over a hidden field rather than a number input: the mockup's shape,
 * and it keeps the value at or above zero without a spinner nobody can hit on a
 * phone. The field is what posts; the <output> is what is read aloud.
 *
 * `submit` and `max` are optional, and that is the difference between the two
 * screens. The student dialog has this as its ONLY control, so it disables
 * saving while the number is unchanged; group settings has it as one field of
 * six, where that would block saving a renamed group. Group settings caps at 10
 * instead, as the mockup does.
 *
 * With JavaScript off the buttons do nothing and the hidden field still carries
 * the saved number, so submitting changes nothing — which is the right no-op
 * for a form whose only control is this one.
 */
class LivesStepperController extends Controller<HTMLElement> {
  static targets = ["field", "output", "up", "down", "submit"]
  static values = { start: Number, max: Number }

  declare readonly fieldTarget: HTMLInputElement
  declare readonly outputTarget: HTMLOutputElement
  declare readonly upTarget: HTMLButtonElement
  declare readonly downTarget: HTMLButtonElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly hasUpTarget: boolean
  declare readonly hasSubmitTarget: boolean
  declare readonly hasMaxValue: boolean
  declare readonly startValue: number
  declare readonly maxValue: number

  connect() {
    this.render()
  }

  up() {
    this.write(this.hasMaxValue ? Math.min(this.maxValue, this.lives + 1) : this.lives + 1)
  }

  down() {
    this.write(Math.max(0, this.lives - 1))
  }

  private write(lives: number) {
    this.fieldTarget.value = String(lives)
    this.render()
  }

  /**
   * Where there is a `submit` target, "Zapisz" is disabled while nothing has
   * changed — pressing it would write the number that is already there. The
   * mockup does the same but also puts the initial focus on that disabled
   * button; focus lives on the stepper here instead.
   */
  private render() {
    const lives = this.lives

    this.outputTarget.textContent = String(lives)
    this.downTarget.disabled = lives === 0
    if (this.hasUpTarget) this.upTarget.disabled = this.hasMaxValue && lives >= this.maxValue
    if (this.hasSubmitTarget) this.submitTarget.disabled = lives === this.startValue
  }

  private get lives(): number {
    const parsed = Number.parseInt(this.fieldTarget.value, 10)

    return Number.isFinite(parsed) && parsed > 0 ? parsed : 0
  }
}

application.register("lives-stepper", LivesStepperController)
