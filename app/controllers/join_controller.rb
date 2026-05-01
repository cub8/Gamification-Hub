# frozen_string_literal: true

class JoinController < ApplicationController
  before_action :set_invite

  def show
    return unless @current_user

    join_story_group
  end

  def create
    return unless @current_user

    join_story_group
  end

  private

  def join_story_group
    @story_group = @invite.story_group

    @student = @story_group.student_memberships.build(user: @current_user)
    @invite.use

    if @student.save
      redirect_to story_group_path(@story_group),
                  notice: 'Student was successfully added to story group.'
    else
      render :show, status: :unprocessable_content
    end

  end

  def set_invite
    @invite = StoryGroupInvite.find_by!(code: params[:code])
  end
end
