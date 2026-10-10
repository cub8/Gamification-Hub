# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/organization_admin_mailer
class OrganizationAdminMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/organization_admin_mailer/invitation_email
  def invitation_email
    OrganizationAdminMailer.with(
      token_link:        'http://example.com/test',
      email:             'jan.nowak@example.com',
      organization_name: 'Uniwersytet',
    ).invitation_email
  end
end
