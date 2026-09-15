import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Native <dialog> driven by Turbo Frame content.
 *
 * Replaces the legacy `turbo_frame_tag "modal"` + `.modal-overlay` pattern.
 * <dialog>.showModal() gives focus trapping, Esc-to-close, ::backdrop and
 * inertness of the page behind it for free — none of which the old overlay had.
 *
 * Markup (in the layout, once):
 *
 *   %dialog.gh-dialog{ data: { controller: "dialog",
 *                              action: "close->dialog#onClose" } }
 *     .gh-dialog-body
 *       = turbo_frame_tag "modal", data: { dialog_target: "frame",
 *                                          action: "turbo:frame-load->dialog#open" }
 *
 * Links open it exactly as before: data: { turbo_frame: "modal" }.
 * Close buttons inside the frame use data: { action: "dialog#close" }, and the
 * dialog itself should carry click->dialog#closeOnBackdrop for light dismiss.
 */
class DialogController extends Controller<HTMLDialogElement> {
  static targets = ["frame"]

  declare readonly frameTarget: HTMLElement

  /**
   * Opens when frame content arrives.
   *
   * Turbo fires turbo:frame-load on the initial EMPTY frame too, so without
   * the emptiness guard every page load would pop a blank dialog.
   */
  open() {
    if (this.isEmpty || this.element.open) return

    this.element.showModal()
  }

  close() {
    this.element.close()
  }

  /**
   * Light dismiss. A native <dialog> does NOT close on an outside click — only
   * Escape is free — so without this the panel could only be dismissed with the
   * keyboard.
   *
   * The ::backdrop is painted by the dialog itself, so a click on it reports
   * the dialog as the target while a click on anything inside reports that
   * child. Comparing target to currentTarget is what separates the two.
   */
  closeOnBackdrop(event: MouseEvent) {
    if (event.target !== event.currentTarget) return

    this.element.close()
  }

  /**
   * Clears the frame on close so reopening the same URL refetches instead of
   * showing the previous contents. `close` fires for Esc and backdrop
   * dismissal too, so this covers every exit path.
   */
  onClose() {
    this.frameTarget.innerHTML = ""
    this.frameTarget.removeAttribute("src")
    this.frameTarget.removeAttribute("complete")
  }

  private get isEmpty(): boolean {
    return this.frameTarget.innerHTML.trim() === ""
  }
}

application.register("dialog", DialogController)
