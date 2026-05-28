import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"
import { application } from "@controllers/application"

interface TurboFrameElement extends HTMLElement {
  reload(): void
}

export default class NotificationsController extends Controller {
  static targets = ["unreadSection", "unreadList", "frame"]
  static values = { url: String }

  declare readonly urlValue: string
  declare readonly hasUnreadSectionTarget: boolean
  declare readonly unreadSectionTarget: HTMLElement
  declare readonly hasUnreadListTarget: boolean
  declare readonly unreadListTarget: HTMLElement
  declare readonly hasFrameTarget: boolean
  declare readonly frameTarget: TurboFrameElement

  private timeoutId: ReturnType<typeof setTimeout> | null = null
  private observer: MutationObserver | null = null
  private readonly DELAY = 2000

  unreadListTargetConnected(element: HTMLElement): void {
    this.setupObserver(element)
  }

  handleShown(): void {
    if (this.hasFrameTarget) {
      this.frameTarget.innerHTML = `
        <div class="p-3 text-center">
          <div class="spinner-border spinner-border-sm text-primary" role="status">
            <span class="visually-hidden">Ładowanie...</span>
          </div>
        </div>
      `
      this.frameTarget.reload()
    }
    this.resetTimer()
  }

  handleHidden(): void {
    this.clearTimer()
  }

  disconnect(): void {
    this.clearTimer()
    this.observer?.disconnect()
  }

  private setupObserver(element: HTMLElement): void {
    this.observer?.disconnect()
    this.observer = new MutationObserver(() => this.handleListChange())
    this.observer.observe(element, { childList: true })
  }

  private handleListChange(): void {
    if (this.hasUnreadSectionTarget && this.hasUnreadListTarget && this.unreadListTarget.children.length > 0) {
      this.unreadSectionTarget.classList.remove("d-none")

      const dropdownMenu = this.element.querySelector(".dropdown-menu")
      if (dropdownMenu?.classList.contains("show")) {
        this.resetTimer()
      }
    }
  }

  private resetTimer(): void {
    this.clearTimer()
    this.timeoutId = setTimeout(() => this.markAsRead(), this.DELAY)
  }

  private clearTimer(): void {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }
  }

  private markAsRead(): void {
    const csrfToken = (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement | null)?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken || "",
        "Accept": "text/vnd.turbo-stream.html",
      },
    })
      .then((response) => response.text())
      .then((html) => {
        if (html) {
          Turbo.renderStreamMessage(html)
        }
      })
      .catch((error) => console.error("Error marking notifications as read:", error))
  }
}

application.register("notifications", NotificationsController)
