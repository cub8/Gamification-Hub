import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { interpolate, pluralize, type PluralForms } from "@utils/i18n"

interface Rung { id: number | string; name: string; min: number; disc: number }

interface Wording {
  required: string
  gives_discount: string
  discount: string
  starting: string
  no_discount: string
  name_placeholder: string
  new_rank: string
  from_short: string
  impact_got_lead: string
  impact_got: PluralForms
  impact_got_tail: string
  impact_nobody: string
  impact_unchanged: string
  impact_changed_lead: string
  impact_changed: PluralForms
  impact_up: string
  impact_down: string
  warn_below: string
  warn_above: string
}

class RankFormController extends Controller<HTMLFormElement> {
  static targets = [
    "name", "threshold", "discount",
    "cardName", "cardArt", "cardRules",
    "draftName", "draftTerms", "draftValue", "draftArt",
    "ladder", "impact", "warnings",
  ]

  static values = {
    rungs: Array,
    totals: Array,
    editingId: Number,
    i18n: Object,
  }

  declare readonly nameTarget: HTMLInputElement
  declare readonly thresholdTarget: HTMLInputElement
  declare readonly discountTarget: HTMLInputElement
  declare readonly cardNameTarget: HTMLElement
  declare readonly cardArtTarget: HTMLElement
  declare readonly cardRulesTarget: HTMLElement
  declare readonly draftNameTarget: HTMLElement
  declare readonly draftTermsTarget: HTMLElement
  declare readonly draftValueTarget: HTMLElement
  declare readonly draftArtTarget: HTMLElement
  declare readonly ladderTarget: HTMLElement
  declare readonly impactTarget: HTMLElement
  declare readonly warningsTarget: HTMLElement
  declare readonly rungsValue: Rung[]
  declare readonly totalsValue: number[]
  declare readonly editingIdValue: number
  declare readonly i18nValue: Wording

  connect() {
    this.refresh()
  }

  refresh() {
    const draft = this.draft

    this.renderCard(draft)
    this.renderDraftRow(draft)
    this.sortLadder()
    this.markClashes()
    this.renderImpact(draft)
    this.renderWarnings(draft)
  }

  private get draft(): Rung {
    return {
      id: this.editing ? this.editingIdValue : "draft",
      name: this.nameTarget.value.trim(),
      min: numberIn(this.thresholdTarget),
      disc: numberIn(this.discountTarget),
    }
  }

  private get editing(): boolean {
    return this.editingIdValue > 0
  }

  private after(draft: Rung): Rung[] {
    const others = this.rungsValue.filter((rung) => rung.id !== draft.id)

    return [...others, draft].sort((a, b) => a.min - b.min)
  }

  private renderCard(draft: Rung) {
    this.cardNameTarget.textContent = draft.name || this.i18nValue.name_placeholder
    this.cardNameTarget.classList.toggle("gh-placeholder-text", draft.name === "")
    this.cardRulesTarget.textContent = this.rewardLine(draft)
    this.renderArt()
  }

  art() {
    this.renderArt()
  }

  private renderArt() {
    const art = this.chosenArt
    if (!art) return

    this.cardArtTarget.replaceChildren(art.cloneNode(true))
    this.draftArtTarget.replaceChildren(art.cloneNode(true))
  }

  private get chosenArt(): Element | null {
    const checked = this.element.querySelector<HTMLInputElement>(
      'input[type="radio"][name$="[icon_glyph]"]:checked',
    )

    return checked?.closest("label")?.querySelector("i")?.firstElementChild ?? null
  }

  private renderDraftRow(draft: Rung) {
    this.draftNameTarget.textContent = draft.name || this.i18nValue.new_rank
    this.draftTermsTarget.textContent = this.ladderTerms(draft)
    this.draftValueTarget.textContent = interpolate(this.i18nValue.from_short, { min: draft.min })
    this.draftRow?.setAttribute("data-min", String(draft.min))
  }

  private get draftRow(): HTMLElement | null {
    return this.ladderTarget.querySelector('[data-rank-id="draft"], .gh-rank-form-rung--draft')
  }

  private sortLadder() {
    const rows = [...this.ladderTarget.children] as HTMLElement[]
    const draft = this.draftRow
    const last = (row: Element) => (row === draft ? 1 : 0)

    rows
      .sort((a, b) => minOf(a) - minOf(b) || last(a) - last(b))
      .forEach((row) => this.ladderTarget.appendChild(row))
  }

  private markClashes() {
    const rows = [...this.ladderTarget.children] as HTMLElement[]

    rows.forEach((row) => {
      const clash = rows.some((other) => other !== row && minOf(other) === minOf(row))
      row.classList.toggle("gh-rank-form-rung--clash", clash)
    })
  }

  private renderImpact(draft: Rung) {
    const { up, down, got } = this.impact(draft)
    const t = this.i18nValue

    if (!this.editing) {
      if (got > 0) {
        this.impactTarget.replaceChildren(
          text(t.impact_got_lead),
          bold(pluralize(t.impact_got, got)),
          text(t.impact_got_tail),
        )
      } else {
        this.impactTarget.replaceChildren(text(t.impact_nobody))
      }

      return
    }

    const moved = up + down
    if (moved === 0) {
      this.impactTarget.replaceChildren(text(t.impact_unchanged))
      return
    }

    const changes = [
      up && interpolate(t.impact_up, { count: up }),
      down && interpolate(t.impact_down, { count: down }),
    ].filter(Boolean)

    this.impactTarget.replaceChildren(
      text(t.impact_changed_lead),
      bold(pluralize(t.impact_changed, moved)),
      text(`: ${changes.join(", ")}.`),
    )
  }

  private impact(draft: Rung) {
    const before = [...this.rungsValue].sort((a, b) => a.min - b.min)
    const after = this.after(draft)
    let up = 0
    let down = 0
    let got = 0

    this.totalsValue.forEach((total) => {
      const was = held(total, before)
      const now = held(total, after)

      if (now?.id === draft.id) got += 1
      if (was?.id === now?.id) return

      if ((now?.min ?? -1) > (was?.min ?? -1)) up += 1
      else down += 1
    })

    return { up, down, got }
  }

  private renderWarnings(draft: Rung) {
    const others = this.rungsValue.filter((rung) => rung.id !== draft.id)
    const below = others.filter((rung) => rung.min < draft.min).sort((a, b) => a.min - b.min).pop()
    const above = others.filter((rung) => rung.min > draft.min).sort((a, b) => a.min - b.min)[0]
    const messages: string[] = []

    if (below && draft.disc < below.disc) {
      messages.push(interpolate(this.i18nValue.warn_below, { name: below.name, other: below.disc, discount: draft.disc }))
    }

    if (above && draft.disc > above.disc) {
      messages.push(interpolate(this.i18nValue.warn_above, { name: above.name, other: above.disc }))
    }

    this.warningsTarget.replaceChildren(...messages.map(warning))
  }

  private rewardLine(rung: Rung): string {
    const line = interpolate(this.i18nValue.required, { min: rung.min })

    return rung.disc > 0 ? `${line} ${interpolate(this.i18nValue.gives_discount, { discount: rung.disc })}` : line
  }

  private ladderTerms(rung: Rung): string {
    if (rung.disc > 0) return interpolate(this.i18nValue.discount, { discount: rung.disc })

    return rung.min === 0 ? this.i18nValue.starting : this.i18nValue.no_discount
  }
}

function numberIn(input: HTMLInputElement): number {
  return Math.max(0, parseInt(input.value, 10) || 0)
}

function minOf(row: Element): number {
  return Number(row.getAttribute("data-min") ?? 0)
}

function held(total: number, ladder: Rung[]): Rung | null {
  return ladder.reduce<Rung | null>(
    (found, rung) => (total >= rung.min ? rung : found),
    null,
  )
}

function text(value: string): Text {
  return document.createTextNode(value)
}

function bold(value: string): HTMLElement {
  const element = document.createElement("b")
  element.textContent = value

  return element
}

function warning(message: string): HTMLElement {
  const paragraph = document.createElement("p")
  const icon = document.createElement("i")
  const span = document.createElement("span")

  paragraph.className = "gh-warning-note--alt"
  icon.className = "fa-solid fa-triangle-exclamation"
  icon.setAttribute("aria-hidden", "true")
  span.textContent = message
  paragraph.append(icon, span)

  return paragraph
}

application.register("rank-form", RankFormController)
