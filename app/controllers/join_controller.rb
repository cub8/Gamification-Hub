# frozen_string_literal: true

class JoinController < ApplicationController
  before_action :set_invite

  # Logika show i create na przyszłość - create to po prostu post do dołączenia użytkownika,
  # show może być widokiem rejestracji, na razie widoczny jest tylko w przypadku błędu

  def show; end

  def create
    join_story_group
  end

  private

  def join_story_group
    service = AcceptInviteService.new(user: @current_user, invite: @invite)
    result = service.call

    if result[:success]
      redirect_to story_group_path(@invite.story_group),
                  notice: 'Student was successfully added to story group.'
    else
      redirect_to home_path
    end
  end

  def set_invite
    @invite = StoryGroupInvite.find_by!(code: params[:code])
    return if @invite

    flash[:alert] = 'Invalid or missing invite code.'
    redirect_to home_path
  end
end
