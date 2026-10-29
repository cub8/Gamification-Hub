# frozen_string_literal: true

class PasswordlessMailer < ApplicationMailer
  helper ApplicationHelper

  def token_email
    @token_link          = params[:token_link]
    @email               = params[:email]
    @first_name          = params[:user_name].to_s.split(' ').first
    @expires_in_minutes  = LoginToken::EXPIRES_IN.in_minutes.to_i

    # Subject: passwordless_mailer.token_email.subject (default_i18n_subject).
    mail to: @email
  end
end
