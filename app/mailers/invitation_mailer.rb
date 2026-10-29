# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  def invitation_email
    @token_link = params[:token_link]
    @email = params[:email]
    @organization_name = params[:organization_name]
    @role_label = t("invitation_mailer.roles.#{params[:role]}")

    # Subject: invitation_mailer.invitation_email.subject (default_i18n_subject).
    mail to: @email
  end
end
