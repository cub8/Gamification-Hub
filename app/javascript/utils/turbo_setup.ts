import "@hotwired/turbo-rails"

Turbo.StreamActions.redirect = function() {
  Turbo.visit(this.target)
}

document.addEventListener("turbo:before-cache", () => {
  const modal = document.getElementById("modal")

  if (modal) {
    modal.innerHTML = ""
  }
})
