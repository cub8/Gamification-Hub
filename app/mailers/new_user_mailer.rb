# frozen_string_literal: true

class NewUserMailer < ApplicationMailer
  def invitation_email
    @token_link = params[:token_link]
    @email = params[:email]
    @organization_name = params[:organization_name]

    mail to: @email, subject: 'Zaproszenie do systemu GamificationHub'
  end
end
