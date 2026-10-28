# frozen_string_literal: true

class InvitationMailerPreview < ActionMailer::Preview
  def admin_invitation_email
    invitation_email(:admin)
  end

  def member_invitation_email
    invitation_email(:member)
  end

  private

  def invitation_email(role)
    InvitationMailer.with(
      token_link:        'http://example.com/test',
      email:             'jan.nowak@example.com',
      organization_name: 'Uniwersytet',
      role:              role,
    ).invitation_email
  end
end
