import "@hotwired/turbo-rails"

Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.target)
}

document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll<HTMLDialogElement>("dialog[open]").forEach((dialog) => {
    dialog.close()
  })

  document.querySelectorAll("#modal, #modal2").forEach((frame) => {
    frame.innerHTML = ""
  })
})
