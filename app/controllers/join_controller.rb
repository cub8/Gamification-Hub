# frozen_string_literal: true

class JoinController < ApplicationController
  before_action :set_invite

  # Logika show i create na przyszłość - create to po prostu post do dołączenia użytkownika,
  # show może być widokiem rejestracji, na razie widoczny jest tylko w przypadku błędu

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
    if @invite.use?

      @story_group = @invite.story_group

      @student = @story_group.student_memberships.build(user: @current_user)
      @invite.use

      if @student.save
        redirect_to story_group_path(@story_group),
                    notice: 'Student was successfully added to story group.'
      else
        render :show, status: :unprocessable_content
      end
    else
      render :show, status: :unprocessable_content
    end
  end

  def set_invite
    @invite = StoryGroupInvite.find_by!(code: params[:code])

    return if @invite

    flash[:alert] = 'Invalid or missing invite code.'
    redirect_to home_path

  end
end
