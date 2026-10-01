import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

export const CROP_EVENT = "gh:image-crop"

const PREVIEW_WIDTH = 256

const PREVIEW_DELAY = 250

class ImageCropController extends Controller<HTMLElement> {
  static targets = ["input", "editor", "box", "ownRadio", "ownPreview"]

  static values = {
    aspect: { type: Number, default: 1.6 },
    width: { type: Number, default: 1024 },
  }

  declare readonly inputTarget: HTMLInputElement
  declare readonly editorTarget: HTMLElement
  declare readonly boxTarget: HTMLElement
  declare readonly ownRadioTarget: HTMLInputElement
  declare readonly hasOwnRadioTarget: boolean
  declare readonly ownPreviewTarget: HTMLImageElement
  declare readonly hasOwnPreviewTarget: boolean
  declare readonly aspectValue: number
  declare readonly widthValue: number

  private cropper: Cropper | null = null
  private objectUrl: string | null = null
  private form: HTMLFormElement | null = null
  private cropped = false
  private timer: number | null = null
  private drawing = false
  private wanted = false

  private storedArt: { hidden: boolean; src: string } = { hidden: true, src: "" }

  connect() {
    this.form = this.element.closest("form")
    this.form?.addEventListener("submit", this.onSubmit)

    this.storedArt = {
      hidden: this.ownTile?.hidden ?? true,
      src: this.hasOwnPreviewTarget ? this.ownPreviewTarget.getAttribute("src") ?? "" : "",
    }
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.onSubmit)
    this.teardown()
  }

  choose() {
    const file = this.inputTarget.files?.[0]
    if (!file) {
      this.teardown()
      return
    }

    this.teardown()
    this.objectUrl = URL.createObjectURL(file)
    this.cropped = false

    const image = document.createElement("img")
    image.src = this.objectUrl
    image.alt = "Wgrana grafika"
    this.boxTarget.replaceChildren(image)

    this.cropper = new Cropper(image, { template: this.template })
    this.editorTarget.hidden = false
    this.selectOwn()
    this.watch()
  }

  pickPreset() {
    if (!this.pending) return

    this.inputTarget.value = ""
    this.teardown()
  }

  pickOwn() {
  }

  private watch() {
    this.cropper?.getCropperSelection()?.addEventListener("change", this.onCropChange)
    this.cropper?.getCropperImage()?.addEventListener("transform", this.onCropChange)

    this.wanted = true
    void this.drawPreview()
  }

  private onCropChange = () => {
    this.wanted = true
    if (this.timer !== null) return

    this.timer = window.setTimeout(() => {
      this.timer = null
      void this.drawPreview()
    }, PREVIEW_DELAY)
  }

  private async drawPreview() {
    if (!this.wanted || this.drawing) return

    this.wanted = false
    this.drawing = true

    try {
      const canvas = await this.render(PREVIEW_WIDTH)
      if (canvas) this.publish(canvas.toDataURL("image/png"))
    } catch {
    }

    this.drawing = false

    if (this.wanted) this.onCropChange()
  }

  private publish(src: string) {
    if (!this.cropper) return

    if (this.hasOwnPreviewTarget) this.ownPreviewTarget.src = src

    this.element.dispatchEvent(new CustomEvent(CROP_EVENT, { bubbles: true, detail: { src } }))
  }

  private onSubmit = (event: SubmitEvent) => {
    if (!this.cropper || this.cropped || !this.pending) return

    event.preventDefault()
    void this.cropAndResubmit()
  }

  private async cropAndResubmit() {
    try {
      const canvas = await this.render(this.widthValue)
      const blob = canvas && (await toBlob(canvas, this.outputType))
      if (blob) this.swapIn(blob)
    } catch {
    }

    this.cropped = true
    this.form?.requestSubmit()
  }

  private render(width: number): Promise<HTMLCanvasElement> | undefined {
    return this.cropper?.getCropperSelection()?.$toCanvas({
      width,
      height: Math.round(width / this.aspectValue),
    })
  }

  private get outputType(): string {
    return this.inputTarget.files?.[0]?.type === "image/png" ? "image/png" : "image/jpeg"
  }

  private swapIn(blob: Blob) {
    const original = this.inputTarget.files?.[0]
    const stem = original ? original.name.replace(/\.[^.]+$/, "") : "grafika"
    const extension = blob.type === "image/png" ? "png" : "jpg"
    const transfer = new DataTransfer()

    transfer.items.add(new File([blob], `${stem}.${extension}`, { type: blob.type }))
    this.inputTarget.files = transfer.files
  }

  private selectOwn() {
    if (!this.hasOwnRadioTarget) return

    const tile = this.ownTile
    if (tile) tile.hidden = false

    this.ownRadioTarget.checked = true
    this.ownRadioTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  private restoreOwn() {
    const tile = this.ownTile
    if (tile) tile.hidden = this.storedArt.hidden

    if (!this.hasOwnPreviewTarget) return

    if (this.storedArt.src) this.ownPreviewTarget.src = this.storedArt.src
    else this.ownPreviewTarget.removeAttribute("src")
  }

  private get ownTile(): HTMLElement | null {
    return this.hasOwnRadioTarget ? this.ownRadioTarget.closest("label") : null
  }

  private get pending(): boolean {
    return (this.inputTarget.files?.length ?? 0) > 0
  }

  private teardown() {
    if (this.timer !== null) clearTimeout(this.timer)
    this.timer = null
    this.drawing = false
    this.wanted = false

    this.cropper?.destroy()
    this.cropper = null
    this.boxTarget.replaceChildren()
    this.editorTarget.hidden = true
    this.restoreOwn()

    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = null
  }

  private get template(): string {
    return `
      <cropper-canvas background>
        <cropper-image rotatable scalable translatable></cropper-image>
        <cropper-shade hidden></cropper-shade>
        <cropper-handle action="select" plain></cropper-handle>
        <cropper-selection initial-coverage="0.9" aspect-ratio="${this.aspectValue}"
                           movable resizable outlined>
          <cropper-grid role="grid" bordered covered></cropper-grid>
          <cropper-crosshair centered></cropper-crosshair>
          <cropper-handle action="move" theme-color="rgba(255, 255, 255, 0.35)"></cropper-handle>
          <cropper-handle action="n-resize"></cropper-handle>
          <cropper-handle action="e-resize"></cropper-handle>
          <cropper-handle action="s-resize"></cropper-handle>
          <cropper-handle action="w-resize"></cropper-handle>
          <cropper-handle action="ne-resize"></cropper-handle>
          <cropper-handle action="nw-resize"></cropper-handle>
          <cropper-handle action="se-resize"></cropper-handle>
          <cropper-handle action="sw-resize"></cropper-handle>
        </cropper-selection>
      </cropper-canvas>
    `
  }
}

function toBlob(canvas: HTMLCanvasElement, type: string): Promise<Blob | null> {
  return new Promise((resolve) => canvas.toBlob(resolve, type, 0.85))
}

application.register("image-crop", ImageCropController)
