import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(window as any).Stimulus = application

export { application }
