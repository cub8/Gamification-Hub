# frozen_string_literal: true

class JoinController < ApplicationController
  before_action :set_invite, except: :new

  # Logika show i create na przyszłość - create to po prostu post do dołączenia użytkownika,
  # show może być widokiem rejestracji, na razie widoczny jest tylko w przypadku błędu

  def show; end

  def create
    service = AcceptInviteService.new(user: @current_user, invite: @invite)
    result = service.call

    if result[:success]
      redirect_to story_group_path(@invite.story_group),
                  notice: 'You have successfully joined the story group!'
    else
      redirect_to home_path, alert: 'Something went wrong'
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
