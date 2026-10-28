# frozen_string_literal: true

module InvitationDelivery
  INVITATION_EXPIRES_IN = 7.days

  private

  def create_invitation_token(user)
    user.create_login_token!(expires_in: INVITATION_EXPIRES_IN)
  end

  def send_invitation(user, token)
    InvitationMailer.with(
      token_link:        auth_passwordless_verify_url(token: token.raw_token),
      email:             user.email,
      organization_name: user.organization.name,
      role:              user.organization_admin? ? :admin : :member,
    ).invitation_email.deliver_later
  end
end
