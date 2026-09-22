# frozen_string_literal: true

# Joining a group: the mockup's three-step flow (js-expanded/10-core.js:288).
#
#   new    -> step 1, the six-character code
#   lookup -> step 2, once a code has been accepted
#   show   -> step 2 as well, reached by scanning a QR code, which already
#             carries the code and so has nothing to ask in step 1
#   create -> step 3, the confirmation that leads into the group
#
# Every step renders either into the shared `modal` frame or as a focused page,
# decided once in `set_presentation`.
class JoinController < ApplicationController
  # Inside the dialog only the frame is used, and the layout already carries a
  # <turbo-frame id="modal"> of its own. Rendering it too would put two frames
  # with the same id in one response and let Turbo pick whichever came first.

  before_action :set_presentation

  # Step 1.
  def new; end

  # Step 1 submitted. A bad code falls back to step 1 carrying its reason.
  def lookup
    @code = params[:code]
    @lookup = InviteLookup.new(user: current_user, code: @code).call

    return render :new, status: :unprocessable_content unless @lookup.ok?

    @story_group = @lookup.story_group
    render :show
  end

  # The QR landing page. Same step, same failure handling — only the wrapper
  # differs, and `set_presentation` has already chosen it.
  def show
    @code = params[:code]
    @lookup = InviteLookup.new(user: current_user, code: @code).call

    return render :new, status: :unprocessable_content unless @lookup.ok?

    @story_group = @lookup.story_group
  end

  # Step 2 submitted.
  def create
    @code = params[:code]
    @lookup = InviteLookup.new(user: current_user, code: @code).call

    return render :new, status: :unprocessable_content unless @lookup.ok?

    accept
  end

  private

  def accept
    service = AcceptInviteService.new(
      user:     current_user,
      invite:   @lookup.invite,
      nickname: params[:nickname],
    )

    @result = service.call
    @story_group = @result.story_group

    return render :show, status: :unprocessable_content unless @result.success?

    @membership = @result.membership
  end

  # A step renders inside the layout's `modal` dialog when it was requested
  # from one, and as a focused, navigation-less page otherwise — which is how
  # the QR link lands. The branch mirrors NotificationsController's `panel`
  # check.
  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
    @chrome = false unless @in_modal
  end
end
