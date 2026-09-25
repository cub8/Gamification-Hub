import { application } from "@controllers/application"
import { Controller } from "@hotwired/stimulus"

/**
 * Type-the-name gate on a destructive confirmation (mockup 30-isg.js:60, 95).
 *
 * Today only "Usuń grupę", which is the one delete in the app that takes
 * everything with it — students, teachers, shop, ranking and every ledger row
 * (DECISIONS.md:28). A click you can make by accident is not enough to ask for
 * that, so the submit stays disabled until the typed value matches the group's
 * name exactly, trimmed. Case-sensitive, as the mockup has it: the point is to
 * make you read the name, and lowering the case lowers the bar.
 *
 * This is the courtesy, NOT the protection. The same comparison runs in
 * StoryGroupsController#destroy, so a request that never met this controller —
 * JavaScript off, or hand-built — is refused there.
 */
class ConfirmNameController extends Controller<HTMLFormElement> {
  static targets = ["input", "submit"]
  static values = { expected: String }

  declare readonly inputTarget: HTMLInputElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly expectedValue: string

  connect() {
    this.check()
  }

  check() {
    this.submitTarget.disabled = this.inputTarget.value.trim() !== this.expectedValue
  }
}

application.register("confirm-name", ConfirmNameController)
