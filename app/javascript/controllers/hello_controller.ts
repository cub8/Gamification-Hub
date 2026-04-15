import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

class HelloController extends Controller {
  connect() {
    this.element.textContent = "Hello World!"
  }
}

application.register("hello", HelloController)
