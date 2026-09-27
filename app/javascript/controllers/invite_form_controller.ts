import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class InviteFormController extends Controller {
  static targets = ["limitSwitch", "expirySwitch", "maxUses", "unit", "date", "time", "summary"]

  static values = {
    summaryPrefix: String,
    limitPrefix: String,
    noLimit: String,
    expiryPrefix: String,
    noExpiry: String,
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

  refresh() {
    this.unitTarget.textContent = this.plural(this.unitFormsValue, this.maxUses)
    this.summaryTarget.textContent = this.summary()
  }

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

  private stamp(): string {
    const [year, month, day] = this.dateTarget.value.split("-")

    if (!year || !month || !day) return ""

    return `${day}.${month}, ${this.timeTarget.value}`
  }

  private get maxUses(): number {
    return Number.parseInt(this.maxUsesTarget.value, 10) || 0
  }

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
