# frozen_string_literal: true

class JoinController < ApplicationController
  before_action :set_invite, except: :new

  def show; end

  def new
    @back_path = request.referrer || home_path
  end

  def create
    service = AcceptInviteService.new(user: @current_user, invite: @invite)
    result = service.call

    if result[:success]
      redirect_to story_group_path(@invite.story_group),
                  notice: 'Pomyślnie dołączono do grupy fabularnej!'
    else
      redirect_to home_path, alert: 'Coś poszło nie tak.'
    end
  end

  private

  def set_invite
    @invite = StoryGroupInvite.find_by(code: params[:code])
    return if @invite

    @error = 'Nieprawidłowy kod zaproszenia.'
    render :new, status: :unprocessable_entity
  end
end
