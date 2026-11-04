# frozen_string_literal: true

class TeacherInvitationsController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_teachers!

  def destroy
    invitation = @story_group.teacher_invitations.find(params.expect(:id))
    invitation.destroy!

    redirect_to story_group_teachers_path(@story_group), status: :see_other,
                                                         notice: t('teachers.invite.flash.cancelled',
                                                                   email: invitation.email,)
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end
end
