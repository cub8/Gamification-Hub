import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

const DISCOUNT_CAP = 50

const EXAMPLE_BADGES = 2

type Part = string | { b: string }

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
  }

  declare readonly ladderDiscountValue: number
  declare readonly ladderRankValue: string
  declare readonly badgeDiscountValue: number
  declare readonly badgeNamesValue: string[]
  declare readonly exampleRankOrderValue: string[]
  declare readonly exampleBadgeOrderValue: string[]

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

  private renderCard() {
    const name = this.nameTarget.value.trim()
    const rules = this.rulesTarget.value.trim()
    const story = this.storyTarget.value.trim()

    this.placeholder(this.frontNameTarget, name, "Nazwa przedmiotu")
    this.placeholder(this.frontRulesTarget, rules, "Co daje studentowi…")

    this.frontFlavorTarget.textContent = story
    this.frontFlavorTarget.hidden = story === ""

    this.frontCostTarget.textContent = String(this.price)
    this.buyLabelTarget.textContent = `Kup za ${this.price}`
    this.needTarget.textContent = String(Math.max(1, Math.ceil(this.price * 0.4)))

    const discount = this.maxDiscount
    this.tagDiscTarget.textContent = `Zniżki do −${discount}%`
    this.tagDiscTarget.hidden = discount === 0
    this.tagLifeTarget.hidden = !this.zeroTarget.checked

    this.thumbNameTarget.textContent = name || "Nazwa przedmiotu"
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
    this.sealLabelTarget.textContent = first
      ? first.kind === "rank"
        ? `Od rangi ${first.name}`
        : `Za odznakę ${first.name}`
      : ""
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
      notes.push(
        gates
          ? `Kupić mogą tylko studenci od rangi ${gate}, więc zniżka dla rang obejmie każdego kupującego.`
          : "Zniżka dla rang obejmie każdego kupującego.",
      )
    }

    const raw = this.rankDiscountReach.discount + this.badgeDiscountValue
    if (raw > DISCOUNT_CAP) {
      notes.push(
        `Zniżki sumują się do ${raw}%, a sklep odejmie najwyżej ${DISCOUNT_CAP}%. ` +
          "Nadwyżka przepada — rozważ niższe zniżki przy rangach i odznakach.",
      )
    }

    const required = new Set(this.chosen(this.unlockBadgeTargets).map(({ name }) => name))
    this.chosen(this.discountBadgeTargets)
      .filter(({ name }) => required.has(name))
      .forEach(({ name }) => {
        notes.push(
          `Odznaka ${name} jest wymagana do zakupu, więc jej zniżka obejmie każdego kupującego.`,
        )
      })

    return notes
  }

  private unlockParts(): Part[] {
    const rank = this.requirements.find(({ kind }) => kind === "rank")?.name ?? ""
    const badges = this.chosen(this.unlockBadgeTargets).map(({ name }) => name)
    const tail = this.zeroTarget.checked
      ? ". Także przy 0 życiach."
      : ", jeśli mają co najmniej 1 życie."

    if (!rank && badges.length === 0) {
      return ["Każdy student może kupić ten przedmiot", tail]
    }

    const parts: Part[] = ["Kupią tylko studenci"]
    if (rank) parts.push(" z rangą ", { b: rank }, " lub wyższą")
    if (badges.length > 0) {
      parts.push(
        `, którzy mają ${badges.length > 1 ? "wszystkie odznaki" : "odznakę"} `,
        { b: andList(badges) },
      )
    }
    parts.push(tail)
    return parts
  }

  private discountParts(): Part[] {
    if (this.maxDiscount === 0) {
      return ["Bez zniżek. Każdy kupujący zapłaci ", { b: String(this.price) }, "."]
    }

    const { rank, badges, percent } = this.example
    if (percent === 0) return []

    const paid = Math.ceil((this.price * (100 - percent)) / 100)

    const names = badges.map((badge) => badge.name)
    const phrase: Part[] | null =
      names.length === 0 ? null : [names.length > 1 ? "odznakami " : "odznaką ", { b: andList(names) }]
    const parts: Part[] = ["Przykładowo: student", ...holderClause(rank, phrase)]
    parts.push(
      " zaoszczędzi ",
      { b: `${percent}%` },
      " i zapłaci ",
      { b: String(paid) },
      ` zamiast ${this.price}.`,
    )
    return parts
  }

  private maxParts(): Part[] {
    const percent = this.maxDiscount
    if (percent === 0) return []

    const reach = this.rankDiscountReach
    const badges = this.badgeNamesValue
    const phrase: Part[] | null =
      badges.length === 0 ? null : badges.length === 1 ? ["odznaką ", { b: badges[0] }] : ["wszystkimi odznakami"]
    const clause = holderClause(reach.discount > 0 ? reach.name : "", phrase)

    return ["Maksymalnie: student", ...clause, " uzyska zniżkę ", { b: `${percent}%` }, "."]
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
      .sort((a, b) => a.localeCompare(b, "pl"))
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
      .sort((a, b) => a.name.localeCompare(b.name, "pl"))
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

function holderClause(rankName: string, badgePhrase: Part[] | null): Part[] {
  const clause: Part[] = []
  if (rankName) clause.push(" z rangą ", { b: rankName })
  if (badgePhrase === null) return clause

  return [...clause, rankName ? " oraz " : " z ", ...badgePhrase]
}

function andList(names: string[]): string {
  if (names.length < 2) return names[0] ?? ""

  return `${names.slice(0, -1).join(", ")} i ${names[names.length - 1]}`
}

application.register("item-form", ItemFormController)
