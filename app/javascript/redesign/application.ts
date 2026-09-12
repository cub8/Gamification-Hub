import { Application } from "@hotwired/stimulus"

/**
 * Stimulus instance for the redesign bundle.
 *
 * Separate from the legacy `@controllers/application` instance so the two
 * bundles never register controllers into each other. Only one of the two
 * bundles is ever loaded on a given page.
 */
const application = Application.start()

application.debug = false

export { application }
