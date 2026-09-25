import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

/** Dispatched on every crop change so the screen's preview can follow. */
export const CROP_EVENT = "gh:image-crop"

/** How wide the live preview is rendered. Small: it is redrawn as you drag. */
const PREVIEW_WIDTH = 256

/** Shortest gap between two preview redraws, in ms. */
const PREVIEW_DELAY = 250

/**
 * The crop half of the shared image field (shared/_image_field).
 *
 * DECISIONS.md:25 makes "presets + upload + crop" a rule for every image in the
 * app, so this controller knows nothing about ranks — badges, items and story
 * group art will mount the same one, passing their own frame's aspect.
 *
 * What it does, once a file is chosen:
 *   1. shows the crop editor and hands the file to Cropper.js,
 *   2. reveals and selects the picker's "Twoja grafika" tile, so the radio
 *      group agrees with what is about to be saved,
 *   3. redraws that tile and fires CROP_EVENT on every drag, which is what
 *      drives the live preview,
 *   4. on submit, renders the selection and swaps the result back into the file
 *      input, so the form posts an ordinary multipart upload and ActiveStorage
 *      needs no direct-upload path.
 *
 * THE CROP IS LOCKED TO THE FRAME'S SHAPE (`aspectValue`, 16:10 for a card's
 * art well). That way an upload fills the well edge to edge and no entity shows
 * the hatched field behind a picture. A square crop could not do that, which is
 * what this replaced.
 *
 * Without JavaScript the editor stays hidden and the raw file posts — a worse
 * frame, but a working form. RanksController#rank_params makes a submitted file
 * win over the preset for exactly that case.
 */
class ImageCropController extends Controller<HTMLElement> {
  static targets = ["input", "editor", "box", "ownRadio", "ownPreview"]

  static values = {
    // 1.6 is `.gh-card-art`'s `aspect-ratio: 16 / 10` (card.css). The two must move
    // together: this is the shape the picture is cut to, that is the shape of
    // the hole it goes into.
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

  /** What the picker tile looked like before anything was uploaded. */
  private storedArt: { hidden: boolean; src: string } = { hidden: true, src: "" }

  /**
   * The submit listener is attached by hand rather than declared as a Stimulus
   * action: the action would have to live on the <form>, and Stimulus only
   * resolves an action against a controller on that element or an ancestor —
   * this one sits on a field inside it.
   */
  connect() {
    this.form = this.element.closest("form")
    this.form?.addEventListener("submit", this.onSubmit)

    // Remembered so abandoning an upload can put the tile back: on a create
    // form there is nothing behind it and the tile has to disappear again,
    // while on an edit form it goes back to showing the stored file.
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

  /** Picking a preset abandons a pending upload, so the two cannot disagree. */
  pickPreset() {
    if (!this.pending) return

    this.inputTarget.value = ""
    this.teardown()
  }

  /** Clicking "Twoja grafika" while a file is pending: nothing to reconcile. */
  pickOwn() {
    // Intentionally empty. The radio carries the choice; this exists so the
    // markup can name an action and read the same as its sibling.
  }

  // ---- live preview --------------------------------------------------------

  /**
   * Cropper v2 emits `change` on the selection and `transform` on the image
   * (moving or zooming the picture under a fixed selection changes the result
   * just as much as dragging the handles), so both are watched. The first draw
   * fires immediately, before anything is touched.
   */
  private watch() {
    this.cropper?.getCropperSelection()?.addEventListener("change", this.onCropChange)
    this.cropper?.getCropperImage()?.addEventListener("transform", this.onCropChange)

    // The opening selection, drawn at once rather than PREVIEW_DELAY later.
    this.wanted = true
    void this.drawPreview()
  }

  /**
   * Throttled, not run per event: a drag fires on every pixel, and each draw is
   * a canvas render plus a PNG encode. This redraws at most once every
   * PREVIEW_DELAY, and always once more after the drag stops, so the preview
   * ends up showing exactly what will be saved.
   */
  private onCropChange = () => {
    this.wanted = true
    if (this.timer !== null) return

    this.timer = window.setTimeout(() => {
      this.timer = null
      void this.drawPreview()
    }, PREVIEW_DELAY)
  }

  private async drawPreview() {
    // `drawing` matters on a slow machine, where one encode can outlast the
    // interval: without it two draws could overlap and finish out of order.
    if (!this.wanted || this.drawing) return

    this.wanted = false
    this.drawing = true

    try {
      const canvas = await this.render(PREVIEW_WIDTH)
      // PNG, not JPEG: the preview has to show transparency the same way the
      // saved file will.
      if (canvas) this.publish(canvas.toDataURL("image/png"))
    } catch {
      // A draw that fails is not worth reporting — the next one will land.
    }

    this.drawing = false

    if (this.wanted) this.onCropChange()
  }

  /**
   * The picker tile is the single source of "what is the art" — the screen's
   * own controller reads it back out of there — so the preview is published by
   * redrawing the tile and saying so.
   */
  private publish(src: string) {
    // teardown() nulls the cropper synchronously, so this is how a draw that
    // was already awaiting an encode knows the upload has since been abandoned
    // — otherwise it would repaint the tile restoreOwn() has just reset.
    if (!this.cropper) return

    if (this.hasOwnPreviewTarget) this.ownPreviewTarget.src = src

    this.element.dispatchEvent(new CustomEvent(CROP_EVENT, { bubbles: true, detail: { src } }))
  }

  // ---- saving --------------------------------------------------------------

  private onSubmit = (event: SubmitEvent) => {
    if (!this.cropper || this.cropped || !this.pending) return

    // The crop is asynchronous, so the first submit is cancelled and replayed
    // once the file has been swapped in.
    event.preventDefault()
    void this.cropAndResubmit()
  }

  private async cropAndResubmit() {
    try {
      const canvas = await this.render(this.widthValue)
      const blob = canvas && (await toBlob(canvas, this.outputType))
      if (blob) this.swapIn(blob)
    } catch {
      // A crop that fails must not block the save: the original file is still
      // in the input, and the server will take it as it is.
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

  /**
   * A PNG in stays a PNG, so a transparent emblem keeps its transparency;
   * anything else becomes a JPEG, so a photo does not come back as a megabyte
   * of lossless pixels. Rank#acceptable_icon takes either.
   */
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

  // ---- the picker tile -----------------------------------------------------

  private selectOwn() {
    if (!this.hasOwnRadioTarget) return

    const tile = this.ownTile
    if (tile) tile.hidden = false

    this.ownRadioTarget.checked = true
    this.ownRadioTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  /** Puts the tile back the way the server rendered it. */
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

    // destroy() unbinds the listeners added in watch() along with everything
    // else Cropper put in the DOM.
    this.cropper?.destroy()
    this.cropper = null
    this.boxTarget.replaceChildren()
    this.editorTarget.hidden = true
    this.restoreOwn()

    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = null
  }

  /**
   * Cropper's default template with one change: `aspect-ratio` on the
   * selection. `aspectRatio` LOCKS the handles, unlike `initialAspectRatio`
   * which only sets the opening shape — locking is the point, because the
   * picture has to fit the frame it is going into.
   */
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

/** canvas.toBlob is callback-based; everything around it here is a promise. */
function toBlob(canvas: HTMLCanvasElement, type: string): Promise<Blob | null> {
  return new Promise((resolve) => canvas.toBlob(resolve, type, 0.85))
}

application.register("image-crop", ImageCropController)
