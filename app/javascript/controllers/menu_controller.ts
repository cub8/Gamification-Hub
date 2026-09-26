import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class MenuController extends Controller {
  open(event: ActionEvent) {
    const dialog = this.dialogFor(event.params.id)

    if (dialog && !dialog.open) dialog.showModal()
  }

  close(event: Event) {
    const dialog = (event.currentTarget as HTMLElement).closest("dialog")

    if (dialog instanceof HTMLDialogElement) dialog.close()
  }

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
