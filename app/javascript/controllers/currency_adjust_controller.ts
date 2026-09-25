import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

type Rung = { v: number; n: string }

/**
 * The live preview in "Koryguj walutę" (mockup 30-student.js:49-55).
 *
 * NEVER WRITES HTML. Every element it touches — the preview list, its rank row,
 * the error, the note, the submit label — is server-rendered by
 * currency_adjustments/_form, so the dialog is correct before this loads and
 * stays correct if it never does. This rewrites text and flips `hidden`.
 *
 * The rule it encodes is DECISIONS.md:32, and it is the whole reason the
 * preview exists: a correction always moves the spendable balance, but only a
 * positive one raises the total collected — so only a positive one can move a
 * rank, and a negative one can never take the balance below zero.
 *
 * No Polish in this file. Every word arrives as a Stimulus value.
 */
class CurrencyAdjustController extends Controller<HTMLFormElement> {
  static targets = [
    "amount", "sign", "box", "error", "errorText",
    "preview", "balance", "total", "rankLabel", "rank", "note", "submit",
  ]

  static values = {
    balance: Number,
    total: Number,
    rungs: Array,
    over: String,
    unchanged: String,
    add: String,
    take: String,
    blank: String,
    addNote: String,
    takeNote: String,
  }

  declare readonly amountTarget: HTMLInputElement
  declare readonly signTargets: HTMLInputElement[]
  declare readonly boxTarget: HTMLElement
  declare readonly errorTarget: HTMLElement
  declare readonly errorTextTarget: HTMLElement
  declare readonly previewTarget: HTMLElement
  declare readonly balanceTarget: HTMLElement
  declare readonly totalTarget: HTMLElement
  declare readonly rankLabelTarget: HTMLElement
  declare readonly rankTarget: HTMLElement
  declare readonly noteTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement

  declare readonly balanceValue: number
  declare readonly totalValue: number
  declare readonly rungsValue: Rung[]
  declare readonly overValue: string
  declare readonly unchangedValue: string
  declare readonly addValue: string
  declare readonly takeValue: string
  declare readonly blankValue: string
  declare readonly addNoteValue: string
  declare readonly takeNoteValue: string

  connect() {
    this.refresh()
  }

  refresh() {
    const amount = this.amount
    const signed = amount * this.sign
    const newBalance = this.balanceValue + signed
    // Only the positive half reaches the total collected.
    const newTotal = this.totalValue + Math.max(signed, 0)
    const overdrawn = newBalance < 0

    this.showError(amount > 0 && overdrawn)
    this.showPreview(amount > 0 && !overdrawn, newBalance, newTotal)
    this.showSubmit(amount, overdrawn)
  }

  private showError(bad: boolean) {
    this.errorTarget.hidden = !bad
    this.boxTarget.classList.toggle("gh-text-input--invalid", bad)

    if (bad) {
      this.errorTextTarget.textContent = this.overValue
      this.amountTarget.setAttribute("aria-invalid", "true")
    } else {
      this.amountTarget.removeAttribute("aria-invalid")
    }
  }

  private showPreview(show: boolean, newBalance: number, newTotal: number) {
    this.previewTarget.hidden = !show
    this.noteTarget.hidden = !show

    if (!show) return

    this.balanceTarget.textContent = `${this.balanceValue} → ${newBalance}`
    this.totalTarget.textContent =
      newTotal === this.totalValue
        ? `${this.totalValue} (${this.unchangedValue})`
        : `${this.totalValue} → ${newTotal}`

    const from = this.rungAt(this.totalValue)
    const to = this.rungAt(newTotal)
    const moved = from?.n !== to?.n

    this.rankLabelTarget.hidden = !moved
    this.rankTarget.hidden = !moved

    if (moved) {
      this.rankTarget.textContent = `${from?.n ?? "—"} → ${to?.n ?? "—"}`
    }

    this.noteTarget.textContent = this.sign > 0 ? this.addNoteValue : this.takeNoteValue
  }

  private showSubmit(amount: number, overdrawn: boolean) {
    const verb = this.sign > 0 ? this.addValue : this.takeValue

    this.submitTarget.textContent = amount > 0 ? `${verb} ${amount}` : this.blankValue
    this.submitTarget.disabled = amount <= 0 || overdrawn
  }

  /** The highest rung at or below what the student would have COLLECTED. */
  private rungAt(collected: number): Rung | undefined {
    return this.rungsValue.filter((rung) => rung.v <= collected).pop()
  }

  private get amount(): number {
    const parsed = Number.parseInt(this.amountTarget.value, 10)

    return Number.isFinite(parsed) && parsed > 0 ? parsed : 0
  }

  private get sign(): number {
    return this.signTargets.find((radio) => radio.checked)?.value === "-1" ? -1 : 1
  }
}

application.register("currency-adjust", CurrencyAdjustController)
