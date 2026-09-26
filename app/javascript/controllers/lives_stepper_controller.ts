import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

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
