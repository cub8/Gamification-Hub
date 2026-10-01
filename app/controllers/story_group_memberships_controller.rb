# frozen_string_literal: true

class StoryGroupMembershipsController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_presentation
  before_action :set_story_group
  before_action :authorize_story_group_read!
  before_action :set_membership

  def edit
    authorize @membership, :edit_own?
  end

  def nickname
    authorize @membership, :edit_own?
  end

  def update
    authorize @membership, :update_own?

    unless @membership.update(membership_params)
      return render(from_dialog? ? :nickname : :edit, status: :unprocessable_content)
    end

    notice = "Twój pseudonim w tej grupie: #{@membership.display_name}."
    return redirect_to(edit_story_group_membership_path(@story_group), notice: notice) unless from_dialog?

    redirect_outside_turbo_frame story_group_ranking_path(@story_group), notice: notice
  end

  def confirm_leave
    authorize @membership, :leave?
  end

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

  def set_membership
    @membership = @story_group.student_memberships.find_by!(user_id: @current_user.id)
  end

  def membership_params
    params.expect(story_group_student: [:nickname])
  end

  def from_dialog?
    params[:return_to] == 'ranking'
  end
end
