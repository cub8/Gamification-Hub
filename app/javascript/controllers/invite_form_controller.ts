import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { interpolate, pluralize, pluralTemplate, type PluralForms } from "@utils/i18n"

// StoryGroupInvitesHelper#invite_form_wording — story_group_invites.summary.*
// plus the locale's short month names, so the date reads like gh_stamp's.
interface Wording {
  sentence: string
  limit: PluralForms
  no_limit: string
  expiry: string
  no_expiry: string
  unit: PluralForms
  stamp: string
  month_names: (string | null)[]
}

class InviteFormController extends Controller {
  static targets = ["limitSwitch", "expirySwitch", "maxUses", "unit", "date", "time", "summary"]

  static values = { i18n: Object }

  declare readonly limitSwitchTarget: HTMLInputElement
  declare readonly expirySwitchTarget: HTMLInputElement
  declare readonly maxUsesTarget: HTMLInputElement
  declare readonly unitTarget: HTMLElement
  declare readonly dateTarget: HTMLInputElement
  declare readonly timeTarget: HTMLInputElement
  declare readonly summaryTarget: HTMLElement

  declare readonly i18nValue: Wording

  connect() {
    this.refresh()
  }

  refresh() {
    this.unitTarget.textContent = pluralTemplate(this.i18nValue.unit, this.maxUses)
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
    return interpolate(this.i18nValue.sentence, { limit: this.limitPhrase(), expiry: this.expiryPhrase() })
  }

  private limitPhrase(): string {
    if (!this.limitSwitchTarget.checked) return this.i18nValue.no_limit

    return pluralize(this.i18nValue.limit, this.maxUses)
  }

  private expiryPhrase(): string {
    if (!this.expirySwitchTarget.checked) return this.i18nValue.no_expiry

    return interpolate(this.i18nValue.expiry, { date: this.stamp() })
  }

  private stamp(): string {
    const [year, month, day] = this.dateTarget.value.split("-")

    if (!year || !month || !day) return ""

    return interpolate(this.i18nValue.stamp, {
      day,
      month,
      dayNumber: Number(day),
      monthName: this.i18nValue.month_names[Number(month)] ?? month,
      time: this.timeTarget.value,
    })
  }

  private get maxUses(): number {
    return Number.parseInt(this.maxUsesTarget.value, 10) || 0
  }
}

application.register("invite-form", InviteFormController)
