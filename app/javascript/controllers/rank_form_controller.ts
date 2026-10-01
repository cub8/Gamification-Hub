import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

interface Rung { id: number | string; name: string; min: number; disc: number }

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
    this.cardNameTarget.textContent = draft.name || "Nazwa rangi"
    this.cardNameTarget.classList.toggle("gh-placeholder-text", draft.name === "")
    this.cardRulesTarget.textContent = rewardLine(draft)
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
    this.draftNameTarget.textContent = draft.name || "Nowa ranga"
    this.draftTermsTarget.textContent = ladderTerms(draft)
    this.draftValueTarget.textContent = `od ${draft.min}`
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

    if (!this.editing) {
      if (got > 0) {
        this.impactTarget.replaceChildren(
          text("Od razu dostanie ją "),
          bold(`${got} ${plural(got, "student", "studentów", "studentów")}`),
          text(". Pozostali zobaczą ją jako kolejny cel."),
        )
      } else {
        this.impactTarget.replaceChildren(
          text("Na razie nikt nie ma tylu zebranych. Studenci zobaczą ją jako kolejny cel."),
        )
      }

      return
    }

    const moved = up + down
    if (moved === 0) {
      this.impactTarget.replaceChildren(text("Żaden student nie zmieni rangi."))
      return
    }

    const changes = [up && `${up} awansuje`, down && `${down} spadnie`].filter(Boolean)

    this.impactTarget.replaceChildren(
      text("Po zapisaniu "),
      bold(`${moved} ${plural(moved, "student zmieni", "studentów zmieni", "studentów zmieni")} rangę`),
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
      messages.push(
        `Ranga niżej (${below.name}) daje −${below.disc}%, a ta tylko −${draft.disc}%. ` +
        "Awans obniżyłby zniżkę.",
      )
    }

    if (above && draft.disc > above.disc) {
      messages.push(
        `Ranga wyżej (${above.name}) daje tylko −${above.disc}%. Awans na nią obniżyłby zniżkę.`,
      )
    }

    this.warningsTarget.replaceChildren(...messages.map(warning))
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

function rewardLine(rung: Rung): string {
  const line = `Wymagane: ${rung.min} zebranych.`

  return rung.disc > 0 ? `${line} Daje −${rung.disc}% w sklepie.` : line
}

function ladderTerms(rung: Rung): string {
  if (rung.disc > 0) return `−${rung.disc}% w sklepie`

  return rung.min === 0 ? "Ranga startowa" : "Bez zniżki"
}

function plural(count: number, one: string, few: string, many: string): string {
  const n = Math.abs(count)
  const lastTwo = n % 100
  const lastOne = n % 10

  if (n === 1) return one
  if (lastOne >= 2 && lastOne <= 4 && (lastTwo < 12 || lastTwo > 14)) return few

  return many
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
