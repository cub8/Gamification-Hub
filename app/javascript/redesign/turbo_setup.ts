import "@hotwired/turbo-rails"

/**
 * Keeps the custom `redirect` stream action used by
 * ApplicationController#redirect_outside_turbo_frame.
 */
Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target)
}

/**
 * Turbo caches a snapshot of the page before navigating away. Without this the
 * cached snapshot keeps the dialog's contents (and its `open` attribute), so
 * going back shows a stale dialog.
 */
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll<HTMLDialogElement>("dialog[open]").forEach((dialog) => {
    dialog.close()
  })

  const frame = document.getElementById("modal")

  if (frame) {
    frame.innerHTML = ""
  }
})
