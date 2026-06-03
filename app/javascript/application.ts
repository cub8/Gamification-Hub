import "@hotwired/turbo-rails"
import "@controllers"
import "bootstrap"
import "@utils/bootstrap_setup"

Turbo.StreamActions.redirect = function() {
  Turbo.visit(this.target)
}
