import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * The invite limits dialog (mockup `mForm`, js-expanded/30-isg.js:33-41).
 *
 * Two jobs, both of them enhancement: fill both switches from a preset chip,
 * and keep the summary sentence and the unit label in step with what is typed.
 *
 * Showing and hiding a limit's fields is NOT one of them — that is a :has()
 * rule in invites.css, so it costs no flash on render and still works with
 * JavaScript off. And the server, not the DOM, decides what becomes NULL:
 * InviteForm reads the checkboxes, so with this controller absent the form
 * still saves the right thing.
 *
 * No Polish lives in here. Every word arrives as a Stimulus value written in
 * the template, and this file only picks a plural index and formats a date.
 */
class InviteFormController extends Controller {
  static targets = ["limitSwitch", "expirySwitch", "maxUses", "unit", "date", "time", "summary"]

  static values = {
    summaryPrefix: String,
    limitPrefix: String,
    noLimit: String,
    expiryPrefix: String,
    noExpiry: String,
    // [one, few, many] — genitive for the sentence, nominative for the unit.
    peopleForms: Array,
    unitForms: Array,
  }

  declare readonly limitSwitchTarget: HTMLInputElement
  declare readonly expirySwitchTarget: HTMLInputElement
  declare readonly maxUsesTarget: HTMLInputElement
  declare readonly unitTarget: HTMLElement
  declare readonly dateTarget: HTMLInputElement
  declare readonly timeTarget: HTMLInputElement
  declare readonly summaryTarget: HTMLElement

  declare readonly summaryPrefixValue: string
  declare readonly limitPrefixValue: string
  declare readonly noLimitValue: string
  declare readonly expiryPrefixValue: string
  declare readonly noExpiryValue: string
  declare readonly peopleFormsValue: string[]
  declare readonly unitFormsValue: string[]

  connect() {
    this.refresh()
  }

  /** Either switch moved, or a field changed. */
  refresh() {
    this.unitTarget.textContent = this.plural(this.unitFormsValue, this.maxUses)
    this.summaryTarget.textContent = this.summary()
  }

  /**
   * A preset fills the form and stops (30-isg.js:83). It is not a mode: the
   * chips never render as selected, because the moment you touch a switch
   * afterwards the preset no longer describes what the form says.
   */
  preset(event: Event) {
    const chip = event.currentTarget as HTMLElement
    const today = chip.dataset.preset === "today"

    this.limitSwitchTarget.checked = false
    this.expirySwitchTarget.checked = today

    if (today) {
      this.dateTarget.value = this.dateTarget.dataset.today ?? this.dateTarget.value
      this.timeTarget.value = this.timeTarget.dataset.endOfDay ?? this.timeTarget.value
    }

    this.refresh()
  }

  private summary(): string {
    return `${this.summaryPrefixValue} ${this.limitPhrase()} ${this.expiryPhrase()}.`
  }

  private limitPhrase(): string {
    if (!this.limitSwitchTarget.checked) return this.noLimitValue

    const count = this.maxUses

    return `${this.limitPrefixValue} ${count} ${this.plural(this.peopleFormsValue, count)}`
  }

  private expiryPhrase(): string {
    if (!this.expirySwitchTarget.checked) return this.noExpiryValue

    return `${this.expiryPrefixValue} ${this.stamp()}`
  }

  /**
   * "30.09, 23:59" from the two inputs' own values. Deliberately string work
   * rather than a Date: an invalid or half-typed date must not throw, and the
   * inputs are already in the user's own zone.
   */
  private stamp(): string {
    const [year, month, day] = this.dateTarget.value.split("-")

    if (!year || !month || !day) return ""

    return `${day}.${month}, ${this.timeTarget.value}`
  }

  private get maxUses(): number {
    return Number.parseInt(this.maxUsesTarget.value, 10) || 0
  }

  /** Polish: 1, then 2-4, then the rest, with the 12-14 exception. */
  private plural(forms: string[], count: number): string {
    const [one, few, many] = forms
    const n = Math.abs(count)
    const lastTwo = n % 100
    const lastOne = n % 10

    if (n === 1) return one
    if (lastOne >= 2 && lastOne <= 4 && (lastTwo < 12 || lastTwo > 14)) return few

    return many
  }
}

application.register("invite-form", InviteFormController)
