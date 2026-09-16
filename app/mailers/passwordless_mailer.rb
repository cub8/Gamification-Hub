# frozen_string_literal: true

class PasswordlessMailer < ApplicationMailer
  helper RedesignHelper

  def token_email
    @token_link          = params[:token_link]
    @email               = params[:email]
    @first_name          = params[:user_name].to_s.split(' ').first
    @expires_in_minutes  = LoginToken::EXPIRES_IN.in_minutes.to_i

    mail to: @email, subject: 'Logowanie do systemu Gamification Hub'
  end
end
