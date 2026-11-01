import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import { fold } from "@utils/fold"

class FilterPickerController extends Controller<HTMLFieldSetElement> {
  static targets = ["input", "list", "option", "chips", "empty"]

  declare readonly inputTarget: HTMLInputElement
  declare readonly listTarget: HTMLElement
  declare readonly optionTargets: HTMLLabelElement[]
  declare readonly chipsTarget: HTMLElement
  declare readonly emptyTarget: HTMLElement

  private active: HTMLLabelElement | null = null

  private readonly closeOnOutsidePress = (event: Event) => {
    if (!this.element.contains(event.target as Node)) this.close()
  }

  connect() {
    document.addEventListener("pointerdown", this.closeOnOutsidePress)
    this.place()
    this.search()
  }

  disconnect() {
    document.removeEventListener("pointerdown", this.closeOnOutsidePress)
  }

  open() {
    this.listTarget.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.listTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.activate(null)
  }

  leave(event: FocusEvent) {
    const next = event.relatedTarget as Node | null

    if (!next || !this.element.contains(next)) this.close()
  }

  keep(event: Event) {
    event.preventDefault()
  }

  sync(event: Event) {
    const picked = !this.listTarget.hidden && this.listTarget.contains(event.target as Node)

    this.place()

    if (event.type === "change" && this.inputTarget.value !== "") this.inputTarget.value = ""

    this.search()

    if (picked) this.inputTarget.focus()
  }

  search() {
    const query = fold(this.inputTarget.value.trim())
    let shown = 0

    this.optionTargets.forEach((option) => {
      const inList = option.parentElement === this.listTarget
      const hit = inList && fold(option.textContent ?? "").includes(query)

      option.hidden = inList && !hit
      if (hit) shown += 1
    })

    this.emptyTarget.hidden = shown > 0
    this.activate(null)
  }

  key(event: KeyboardEvent) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.open()
        this.step(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.open()
        this.step(-1)
        break
      case "Enter":
        event.preventDefault()
        this.active?.click()
        break
      case "Escape":
        if (!this.listTarget.hidden) {
          event.preventDefault()
          event.stopPropagation()
          this.close()
        }
        break
    }
  }

  private place() {
    this.optionTargets.forEach((option) => {
      const ticked = this.boxIn(option).checked

      option.classList.toggle("gh-choice-chip", ticked)
      option.classList.toggle("gh-octagon-clip", ticked)
      option.setAttribute("aria-selected", String(ticked))

      if (ticked) this.chipsTarget.append(option)
      else this.emptyTarget.before(option)
    })
  }

  private step(direction: 1 | -1) {
    const visible = this.optionTargets.filter(
      (option) => option.parentElement === this.listTarget && !option.hidden,
    )
    if (visible.length === 0) return

    const at = this.active ? visible.indexOf(this.active) : -1
    const next = (at + direction + visible.length) % visible.length

    this.activate(visible[next])
    visible[next].scrollIntoView({ block: "nearest" })
  }

  private activate(option: HTMLLabelElement | null) {
    this.active?.classList.remove("is-active")
    this.active = option
    option?.classList.add("is-active")

    if (option) this.inputTarget.setAttribute("aria-activedescendant", option.id)
    else this.inputTarget.removeAttribute("aria-activedescendant")
  }

  private boxIn(option: HTMLElement): HTMLInputElement {
    return option.querySelector<HTMLInputElement>('input[type="checkbox"]')!
  }
}

application.register("filter-picker", FilterPickerController)
