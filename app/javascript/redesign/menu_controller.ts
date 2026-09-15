import { application } from "@redesign/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Plain server-rendered <dialog>s: the avatar menu and the mobile "Więcej"
 * sheet.
 *
 * Deliberately separate from `dialog_controller`, which opens on
 * `turbo:frame-load` and must keep doing only that — these dialogs have their
 * content already in the page and are opened by a click.
 *
 * The controller sits on the shell rather than on each dialog, because the
 * triggers live in the header and the tab bar while the dialogs are rendered
 * once at the end of the layout. Triggers name their dialog by id:
 *
 *   %button{ data: { action: "menu#open", menu_id_param: "gh-more-sheet" } }
 *
 * showModal() gives focus trapping, Esc-to-close, ::backdrop and inertness of
 * the page behind it for free.
 */
class MenuController extends Controller {
  /** Opens the dialog named by the trigger's `data-menu-id-param`. */
  open(event: ActionEvent) {
    const dialog = this.dialogFor(event.params.id)

    if (dialog && !dialog.open) dialog.showModal()
  }

  close(event: Event) {
    const dialog = (event.currentTarget as HTMLElement).closest("dialog")

    if (dialog instanceof HTMLDialogElement) dialog.close()
  }

  /**
   * Backdrop click. The ::backdrop is painted by the dialog itself, so a click
   * on it reports the dialog as the target; a click on anything inside reports
   * that child. Comparing target to currentTarget is what separates the two.
   */
  closeOnBackdrop(event: MouseEvent) {
    if (event.target !== event.currentTarget) return

    const dialog = event.currentTarget as HTMLDialogElement

    dialog.close()
  }

  private dialogFor(id: string | undefined): HTMLDialogElement | null {
    if (!id) return null

    const element = document.getElementById(id)

    return element instanceof HTMLDialogElement ? element : null
  }
}

interface ActionEvent extends Event {
  params: { id?: string }
}

application.register("menu", MenuController)
