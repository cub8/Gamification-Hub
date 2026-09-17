# frozen_string_literal: true

# "Ustawienia w grupie" (mockup #/s/group-settings): what a STUDENT controls
# about their own place in one group — their nickname, what the teacher can see,
# and the way out.
#
# Singular and always self-addressed: the membership comes from the current
# user, never from a parameter, so there is no id here to tamper with. The
# policy still asks (`edit_own?`, `leave?`), because a route that trusts its own
# lookup is one refactor away from trusting a parameter.
#
# The teacher's side of the same record is StudentsController. The two are
# deliberately separate: removing a student and leaving a group destroy the same
# row but are different acts, with different copy and different permission.
class StoryGroupMembershipsController < ApplicationController
  include StoryGroupAuthorization

  # Editing is a page; only the leave confirmation is a dialog, and inside the
  # dialog only the frame is used — the redesign layout already carries a
  # <turbo-frame id="modal"> and two with one id let Turbo pick whichever came
  # first.
  layout -> { @in_modal ? false : 'redesign' }
  # RedesignLayout is all-or-nothing and this controller needs its own layout
  # lambda, so its second line is inlined here: under
  # `include_all_helpers = false` the gh_* helpers do not arrive on their own.
  helper RedesignHelper

  before_action :set_presentation
  before_action :set_story_group
  before_action :authorize_story_group_read!
  before_action :set_membership

  # GET /story_groups/:story_group_id/membership/edit
  def edit
    authorize @membership, :edit_own?
  end

  # PATCH /story_groups/:story_group_id/membership
  def update
    authorize @membership, :update_own?

    if @membership.update(membership_params)
      redirect_to edit_story_group_membership_path(@story_group),
                  notice: "Twój pseudonim w tej grupie: #{@membership.display_name}."
    else
      render :edit, status: :unprocessable_content
    end
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
end
