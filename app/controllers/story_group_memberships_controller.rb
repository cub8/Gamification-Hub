# frozen_string_literal: true

class StoryGroupMembershipsController < ApplicationController
  include StoryGroupAuthorization

  # Editing is a page; only the leave confirmation is a dialog, and inside the
  # dialog only the frame is used — the layout already carries a
  # <turbo-frame id="modal"> and two with one id let Turbo pick whichever came
  # first.

  before_action :set_presentation
  before_action :set_story_group
  before_action :authorize_story_group_read!
  before_action :set_membership

  # GET /story_groups/:story_group_id/membership/edit
  def edit
    authorize @membership, :edit_own?
  end

  def nickname
    authorize @membership, :edit_own?
  end

  # PATCH /story_groups/:story_group_id/membership
  def update
    authorize @membership, :update_own?

    unless @membership.update(membership_params)
      return render(from_dialog? ? :nickname : :edit, status: :unprocessable_content)
    end

    notice = "Twój pseudonim w tej grupie: #{@membership.display_name}."
    # Out of the dialog and back to the board the nickname is printed on;
    # otherwise the settings page it was edited on, which is where it stays.
    return redirect_to(edit_story_group_membership_path(@story_group), notice: notice) unless from_dialog?

    redirect_outside_turbo_frame story_group_ranking_path(@story_group), notice: notice
  end

  # GET /story_groups/:story_group_id/membership/confirm_leave
  #
  # Leaving is a hard delete: the badges, the purchases and the whole currency
  # history go with the membership. The dialog counts them, because that is the
  # part a student cannot see coming.
  def confirm_leave
    authorize @membership, :leave?
  end

  # DELETE /story_groups/:story_group_id/membership
  def destroy
    authorize @membership, :leave?

    name = @story_group.name
    @membership.destroy!

    redirect_to story_groups_path, notice: "Opuszczono grupę #{name}.", status: :see_other
  end

  private

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  # find_by! and not find_by: a teacher of this group passes
  # authorize_story_group_read! but has no membership, and 404 is the honest
  # answer — this screen is not theirs.
  def set_membership
    @membership = @story_group.student_memberships.find_by!(user_id: @current_user.id)
  end

  # The nickname and nothing else. Lives, currency and rank belong to the
  # teacher's screens; this form must not be able to reach them.
  def membership_params
    params.expect(story_group_student: [:nickname])
  end

  # Where this save came from, as a FLAG rather than a path: the form hands over
  # one known word and the controller decides what it means, so a caller can
  # never post its own redirect target here.
  def from_dialog?
    params[:return_to] == 'ranking'
  end
end
