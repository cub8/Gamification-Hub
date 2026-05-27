declare module "stimulus-flatpickr" {
  import { Controller } from "@hotwired/stimulus"
  export default class Flatpickr extends Controller {
    config: any
    fp: any
    initialize(): void
    connect(): void
    disconnect(): void
  }
}
