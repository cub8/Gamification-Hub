import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Resend cooldown on the "Sprawdź skrzynkę" screen.
 *
 * The server renders the starting seconds (derived from when the link was
 * actually sent, not from page load), so a refresh resumes the countdown
 * instead of restarting it. This is presentational only — the real limit is
 * the Rack::Attack throttle on POST /auth/passwordless.
 *
 * Both labels come from the view so the Polish copy stays in the template.
 * The waiting label contains a %{time} placeholder.
 */
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

    // Derive from the clock rather than decrementing a counter: immune to
    // setInterval drift and to background-tab throttling.
    this.deadline = Date.now() + this.secondsValue * 1000
    this.tick()
    this.timer = window.setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    this.stop()
    // Turbo caches a snapshot on navigate-away; without this it would freeze
    // at "Wyślij ponownie za 0:07". connect() re-derives state from the
    // server-rendered value, so correctness never depends on this reset.
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
