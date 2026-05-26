// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "@controllers"
import "bootstrap"
import "@fortawesome/fontawesome-free/js/all"

import "@utils/bootstrap_setup"

Turbo.StreamActions.redirect = function() {
  Turbo.visit(this.target)
}
