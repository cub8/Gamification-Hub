import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class CountdownController extends Controller {
  static targets = ["button"]
  static values = {
    seconds: Number,
    idleLabel: String,
    waitingLabel: String,
  }

  declare readonly buttonTarget: HTMLButtonElement
  declare readonly hasButtonTarget: boolean
  declare readonly secondsValue: number
  declare readonly idleLabelValue: string
  declare readonly waitingLabelValue: string

  private deadline = 0
  private timer?: number

  connect() {
    if (!this.hasButtonTarget || this.secondsValue <= 0) return this.finish()

    this.deadline = Date.now() + this.secondsValue * 1000
    this.tick()
    this.timer = window.setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    this.stop()
    this.restore()
  }

  private tick() {
    const remaining = Math.ceil((this.deadline - Date.now()) / 1000)

    if (remaining <= 0) return this.finish()

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = this.waitingLabelValue.replace("%{time}", this.mmss(remaining))
  }

  private finish() {
    this.stop()
    this.restore()
  }

  private stop() {
    if (this.timer !== undefined) {
      window.clearInterval(this.timer)
      this.timer = undefined
    }
  }

  private restore() {
    if (!this.hasButtonTarget) return

    this.buttonTarget.disabled = false
    this.buttonTarget.textContent = this.idleLabelValue
  }

  private mmss(seconds: number): string {
    const m = Math.floor(seconds / 60)
    const s = seconds % 60

    return `${m}:${String(s).padStart(2, "0")}`
  }
}

application.register("countdown", CountdownController)
