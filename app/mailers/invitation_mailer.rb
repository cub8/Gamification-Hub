# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  ROLE_LABELS = {
    admin:  'administrator',
    member: 'członek',
  }.freeze

  def invitation_email
    @token_link = params[:token_link]
    @email = params[:email]
    @organization_name = params[:organization_name]
    @role_label = ROLE_LABELS[params[:role]]

    mail to: @email, subject: 'Zaproszenie do systemu GamificationHub'
  end
end
