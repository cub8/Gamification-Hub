import Flatpickr from "stimulus-flatpickr"
import { application } from "@controllers/application"

import { Polish } from "flatpickr/dist/l10n/pl.js"

class FlatpickrController extends Flatpickr {
  connect() {
    this.config = {
      ...this.config,
      locale: Polish,
    }
    super.connect()
  }
}

application.register("flatpickr", FlatpickrController)
