# frozen_string_literal: true

class PasswordlessMailer < ApplicationMailer
  def token_email
    @token_link = params[:token_link]
    @email = params[:email]
    @user_name = params[:user_name]

    mail to: @email, subject: 'Logowanie do systemu GamificationHub'
  end
end
