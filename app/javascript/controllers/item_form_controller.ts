import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { andList, interpolate, locale, pluralTemplate, type PluralForms } from "@utils/i18n"

const DISCOUNT_CAP = 50

const EXAMPLE_BADGES = 2

type Part = string | { b: string }

// ItemsHelper#item_form_wording — the same templates the server fills.
interface Wording {
  unlock_everyone: string
  unlock_restricted: string
  unlock_rank: string
  unlock_badges: PluralForms
  lives_yes: string
  lives_no: string
  no_discount: string
  example: string
  max: string
  holder_rank: string
  holder_badges: PluralForms
  holder_all_badges: string
  holder_join_and: string
  holder_join_with: string
  warn_cap: string
  warn_rank_everyone: string
  warn_rank_gate: string
  warn_badge_required: string
  discount_up_to: string
  seal_rank: string
  seal_badge: string
  name_placeholder: string
  rules_placeholder: string
  buy: string
}

class ItemFormController extends Controller<HTMLFormElement> {
  static targets = [
    "name", "rules", "story", "price", "zero", "unlockRank", "discountRank",
    "unlockBadge", "discountBadge",
    "card", "frontName", "frontCost", "frontArt", "seal", "sealLabel",
    "tagDisc", "tagLife", "frontRules", "frontFlavor",
    "footAfford", "footSave", "footSealed", "buyLabel", "need", "bar", "reqList",
    "state", "sealHint",
    "reqRank", "reqBadge", "warnTemplate",
    "unlockText", "discountText", "discountMax", "warnings",
    "thumbArt", "thumbName",
  ]

  static values = {
    ladderDiscount: Number,
    ladderRank: String,
    badgeDiscount: Number,
    badgeNames: Array,
    exampleRankOrder: Array,
    exampleBadgeOrder: Array,
    i18n: Object,
  }

  declare readonly ladderDiscountValue: number
  declare readonly ladderRankValue: string
  declare readonly badgeDiscountValue: number
  declare readonly badgeNamesValue: string[]
  declare readonly exampleRankOrderValue: string[]
  declare readonly exampleBadgeOrderValue: string[]
  declare readonly i18nValue: Wording

  declare readonly nameTarget: HTMLInputElement
  declare readonly rulesTarget: HTMLTextAreaElement
  declare readonly storyTarget: HTMLTextAreaElement
  declare readonly priceTarget: HTMLInputElement
  declare readonly zeroTarget: HTMLInputElement
  declare readonly unlockRankTarget: HTMLSelectElement
  declare readonly discountRankTarget: HTMLSelectElement
  declare readonly unlockBadgeTargets: HTMLElement[]
  declare readonly discountBadgeTargets: HTMLElement[]
  declare readonly cardTarget: HTMLElement
  declare readonly frontNameTarget: HTMLElement
  declare readonly frontCostTarget: HTMLElement
  declare readonly frontArtTarget: HTMLElement
  declare readonly sealTarget: HTMLElement
  declare readonly sealLabelTarget: HTMLElement
  declare readonly tagDiscTarget: HTMLElement
  declare readonly tagLifeTarget: HTMLElement
  declare readonly frontRulesTarget: HTMLElement
  declare readonly frontFlavorTarget: HTMLElement
  declare readonly footAffordTarget: HTMLElement
  declare readonly footSaveTarget: HTMLElement
  declare readonly footSealedTarget: HTMLElement
  declare readonly buyLabelTarget: HTMLElement
  declare readonly needTarget: HTMLElement
  declare readonly barTarget: HTMLElement
  declare readonly reqListTarget: HTMLElement
  declare readonly stateTargets: HTMLButtonElement[]
  declare readonly sealHintTarget: HTMLElement
  declare readonly reqRankTarget: HTMLTemplateElement
  declare readonly reqBadgeTarget: HTMLTemplateElement
  declare readonly warnTemplateTarget: HTMLTemplateElement
  declare readonly unlockTextTarget: HTMLElement
  declare readonly discountTextTarget: HTMLElement
  declare readonly discountMaxTarget: HTMLElement
  declare readonly warningsTarget: HTMLElement
  declare readonly thumbArtTarget: HTMLElement
  declare readonly thumbNameTarget: HTMLElement

  private currentState: "afford" | "save" | "sealed" = "afford"

  connect() {
    this.refresh()
  }

  refresh() {
    this.renderCard()
    this.renderRequirements()
    this.renderSentences()
    this.applyState()
    this.renderArt()
  }

  art() {
    this.renderArt()
  }

  state(event: Event) {
    const button = event.currentTarget as HTMLButtonElement
    this.currentState = button.value as typeof this.currentState
    this.applyState()
  }

  private get t(): Wording {
    return this.i18nValue
  }

  private renderCard() {
    const name = this.nameTarget.value.trim()
    const rules = this.rulesTarget.value.trim()
    const story = this.storyTarget.value.trim()

    this.placeholder(this.frontNameTarget, name, this.t.name_placeholder)
    this.placeholder(this.frontRulesTarget, rules, this.t.rules_placeholder)

    this.frontFlavorTarget.textContent = story
    this.frontFlavorTarget.hidden = story === ""

    this.frontCostTarget.textContent = String(this.price)
    this.buyLabelTarget.textContent = interpolate(this.t.buy, { price: this.price })
    this.needTarget.textContent = String(Math.max(1, Math.ceil(this.price * 0.4)))

    const discount = this.maxDiscount
    this.tagDiscTarget.textContent = interpolate(this.t.discount_up_to, { discount })
    this.tagDiscTarget.hidden = discount === 0
    this.tagLifeTarget.hidden = !this.zeroTarget.checked

    this.thumbNameTarget.textContent = name || this.t.name_placeholder
  }

  private renderRequirements() {
    const requirements = this.requirements
    const lines = requirements.map(({ kind, name }) => {
      const template = kind === "rank" ? this.reqRankTarget : this.reqBadgeTarget
      const line = template.content.cloneNode(true) as DocumentFragment
      const slot = line.querySelector("b")
      if (slot) slot.textContent = name
      return line
    })

    this.reqListTarget.replaceChildren(...lines)

    const first = requirements[0]
    const seal = first?.kind === "rank" ? this.t.seal_rank : this.t.seal_badge
    this.sealLabelTarget.textContent = first ? interpolate(seal, { name: first.name }) : ""
  }

  private renderSentences() {
    this.writeSentence(this.unlockTextTarget, this.unlockParts())
    this.writeSentence(this.discountTextTarget, this.discountParts())
    this.writeSentence(this.discountMaxTarget, this.maxParts())

    const notes = this.warnings.map((text) => {
      const note = this.warnTemplateTarget.content.cloneNode(true) as DocumentFragment
      const slot = note.querySelector("span")
      if (slot) slot.textContent = text
      return note
    })
    this.warningsTarget.replaceChildren(...notes)
  }

  private applyState() {
    const sealable = this.requirements.length > 0
    if (!sealable && this.currentState === "sealed") this.currentState = "afford"

    this.sealHintTarget.hidden = sealable
    this.stateTargets.forEach((button) => {
      if (button.value === "sealed") button.disabled = !sealable
      button.setAttribute("aria-pressed", String(button.value === this.currentState))
    })

    this.cardTarget.classList.toggle("gh-card--sealed", this.currentState === "sealed")
    this.sealTarget.hidden = this.currentState !== "sealed"
    this.footAffordTarget.hidden = this.currentState !== "afford"
    this.footSaveTarget.hidden = this.currentState !== "save"
    this.footSealedTarget.hidden = this.currentState !== "sealed"
  }

  private renderArt() {
    const art = this.chosenArt
    if (!art) return

    this.frontArtTarget.replaceChildren(art.cloneNode(true))
    this.thumbArtTarget.replaceChildren(art.cloneNode(true))
  }

  private get price(): number {
    return Math.max(1, parseInt(this.priceTarget.value, 10) || 0)
  }

  private get requirements(): { kind: "rank" | "badge"; name: string }[] {
    const option = this.selectedOption(this.unlockRankTarget)
    const rank = option?.dataset.ghGates === "true" ? (option.dataset.ghName ?? "") : ""
    const badges = this.chosen(this.unlockBadgeTargets).map(({ name }) => name)

    return [
      ...(rank ? [{ kind: "rank" as const, name: rank }] : []),
      ...badges.map((name) => ({ kind: "badge" as const, name })),
    ]
  }

  private get rankDiscountReach(): { discount: number; name: string } {
    const floor = this.discountRankTarget.selectedIndex > 0
    const alone = this.chosen(this.discountBadgeTargets).length === 0

    if (floor && alone) {
      return {
        discount: this.selectedDiscount(this.discountRankTarget),
        name: this.selectedName(this.discountRankTarget),
      }
    }

    return { discount: this.ladderDiscountValue, name: this.ladderRankValue }
  }

  private get maxDiscount(): number {
    return Math.min(DISCOUNT_CAP, this.rankDiscountReach.discount + this.badgeDiscountValue)
  }

  private get warnings(): string[] {
    const notes: string[] = []
    const gateOption = this.selectedOption(this.unlockRankTarget)
    const gate = gateOption?.dataset.ghName ?? ""
    const gates = gateOption?.dataset.ghGates === "true"
    const floorIndex = this.discountRankTarget.selectedIndex
    const gateIndex = this.unlockRankTarget.selectedIndex

    if (gate && floorIndex > 0 && gateIndex >= floorIndex) {
      notes.push(gates ? interpolate(this.t.warn_rank_gate, { rank: gate }) : this.t.warn_rank_everyone)
    }

    const raw = this.rankDiscountReach.discount + this.badgeDiscountValue
    if (raw > DISCOUNT_CAP) {
      notes.push(interpolate(this.t.warn_cap, { raw, cap: DISCOUNT_CAP }))
    }

    const required = new Set(this.chosen(this.unlockBadgeTargets).map(({ name }) => name))
    this.chosen(this.discountBadgeTargets)
      .filter(({ name }) => required.has(name))
      .forEach(({ name }) => {
        notes.push(interpolate(this.t.warn_badge_required, { name }))
      })

    return notes
  }

  private unlockParts(): Part[] {
    const rank = this.requirements.find(({ kind }) => kind === "rank")?.name ?? ""
    const badges = this.chosen(this.unlockBadgeTargets).map(({ name }) => name)
    const lives = this.zeroTarget.checked ? this.t.lives_yes : this.t.lives_no

    if (!rank && badges.length === 0) {
      return fill(this.t.unlock_everyone, { lives })
    }

    return fill(this.t.unlock_restricted, {
      rank: rank ? fill(this.t.unlock_rank, { rank: { b: rank } }) : [],
      badges: this.badgePhrase(this.t.unlock_badges, badges) ?? [],
      lives,
    })
  }

  // "odznaką X" / "odznakami X i Y" — a plural template filled with the names.
  private badgePhrase(forms: PluralForms, names: string[]): Part[] | null {
    if (names.length === 0) return null

    return fill(pluralTemplate(forms, names.length), { badges: { b: andList(names) } })
  }

  private discountParts(): Part[] {
    if (this.maxDiscount === 0) {
      return fill(this.t.no_discount, { price: { b: String(this.price) } })
    }

    const { rank, badges, percent } = this.example
    if (percent === 0) return []

    const paid = Math.ceil((this.price * (100 - percent)) / 100)

    const phrase = this.badgePhrase(this.t.holder_badges, badges.map((badge) => badge.name))

    return fill(this.t.example, {
      holder: this.holderClause(rank, phrase),
      percent: { b: `${percent}%` },
      paid: { b: String(paid) },
      price: String(this.price),
    })
  }

  private maxParts(): Part[] {
    const percent = this.maxDiscount
    if (percent === 0) return []

    const reach = this.rankDiscountReach
    const badges = this.badgeNamesValue
    const phrase = badges.length > 1 ? [this.t.holder_all_badges] : this.badgePhrase(this.t.holder_badges, badges)

    return fill(this.t.max, {
      holder: this.holderClause(reach.discount > 0 ? reach.name : "", phrase),
      percent: { b: `${percent}%` },
    })
  }

  private holderClause(rankName: string, badgePhrase: Part[] | null): Part[] {
    const rank = rankName ? fill(this.t.holder_rank, { rank: { b: rankName } }) : []
    if (badgePhrase === null) return rank

    const join = rankName ? this.t.holder_join_and : this.t.holder_join_with
    return [...rank, ...fill(join, { phrase: badgePhrase })]
  }

  private get example(): { rank: string; badges: { name: string; discount: number }[]; percent: number } {
    const rank = this.exampleRank
    const badges = this.exampleBadges
    const total = (rank?.discount ?? 0) + badges.reduce((sum, b) => sum + b.discount, 0)

    return { rank: rank?.name ?? "", badges, percent: Math.min(DISCOUNT_CAP, total) }
  }

  private get exampleRank(): { name: string; discount: number } | null {
    const floorIndex = this.discountRankTarget.selectedIndex
    const ladder = [...this.discountRankTarget.options].slice(1)
    const pool = floorIndex > 0 ? ladder.slice(floorIndex - 1) : ladder

    const earning = new Map(
      pool
        .map(
          (option) =>
            [option.dataset.ghOwnName ?? "", parseInt(option.dataset.ghOwn ?? "0", 10) || 0] as const,
        )
        .filter(([, own]) => own > 0),
    )

    const name = this.exampleRankOrderValue.find((candidate) => earning.has(candidate))
    return name ? { name, discount: earning.get(name)! } : null
  }

  private get exampleBadges(): { name: string; discount: number }[] {
    const all = new Map(this.allBadges.map((badge) => [badge.name, badge.discount]))
    const picked: string[] = []

    if (this.discountRankTarget.selectedIndex === 0) {
      const listed = new Set(this.chosen(this.discountBadgeTargets).map(({ name }) => name))
      if (listed.size > 0) {
        const earning = this.exampleBadgeOrderValue.filter((n) => listed.has(n) && (all.get(n) ?? 0) > 0)
        const forced = earning[0] ?? this.exampleBadgeOrderValue.find((n) => listed.has(n))
        if (forced) picked.push(forced)
      }
    }

    for (const name of this.exampleBadgeOrderValue) {
      if (picked.length >= EXAMPLE_BADGES) break
      if (!picked.includes(name) && (all.get(name) ?? 0) > 0) picked.push(name)
    }

    return picked
      .sort((a, b) => a.localeCompare(b, locale()))
      .map((name) => ({ name, discount: all.get(name) ?? 0 }))
  }

  private get allBadges(): { name: string; discount: number }[] {
    return this.discountBadgeTargets.map((chip) => ({
      name: chip.dataset.ghName ?? "",
      discount: parseInt(chip.dataset.ghDiscount ?? "0", 10) || 0,
    }))
  }

  private writeSentence(target: HTMLElement, parts: Part[]) {
    const nodes = parts.map((part) => {
      if (typeof part === "string") return document.createTextNode(part)

      const bold = document.createElement("b")
      bold.textContent = part.b
      return bold
    })

    target.replaceChildren(...nodes)
  }

  private chosen(chips: HTMLElement[]): { name: string; discount: number }[] {
    return chips
      .filter((chip) => chip.querySelector<HTMLInputElement>('input[type="checkbox"]')?.checked)
      .map((chip) => ({
        name: chip.dataset.ghName ?? "",
        discount: parseInt(chip.dataset.ghDiscount ?? "0", 10) || 0,
      }))
      .sort((a, b) => a.name.localeCompare(b.name, locale()))
  }

  private selectedOption(select: HTMLSelectElement): HTMLOptionElement | undefined {
    return select.selectedOptions[0]
  }

  private selectedName(select: HTMLSelectElement): string {
    return this.selectedOption(select)?.dataset.ghName ?? ""
  }

  private selectedDiscount(select: HTMLSelectElement): number {
    return parseInt(this.selectedOption(select)?.dataset.ghDiscount ?? "0", 10) || 0
  }

  private get chosenArt(): Element | null {
    const checked = this.element.querySelector<HTMLInputElement>(
      'input[type="radio"][name$="[icon_glyph]"]:checked',
    )

    return checked?.closest("label")?.querySelector("i")?.firstElementChild ?? null
  }

  private placeholder(element: HTMLElement, value: string, fallback: string) {
    element.textContent = value || fallback
    element.classList.toggle("gh-placeholder-text", value === "")
  }
}

// The client twin of ApplicationHelper#gh_fill: splits a template on its
// %{slots} and drops in plain text, bold names or already-built fragments.
function fill(template: string, vars: Record<string, Part | Part[]>): Part[] {
  return template.split(/(%\{\w+\})/).flatMap((piece): Part[] => {
    const key = /^%\{(\w+)\}$/.exec(piece)?.[1]
    if (key === undefined) return piece === "" ? [] : [piece]

    const value = vars[key]
    if (value === undefined) return [piece]

    return Array.isArray(value) ? value : [value]
  })
}

application.register("item-form", ItemFormController)
