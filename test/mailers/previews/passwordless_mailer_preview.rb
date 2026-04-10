# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/passwordless_mailer
class PasswordlessMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/passwordless_mailer/token_email
  def token_email
    token_link = 'http://example.com/test'
    email = 'jan.nowak@example.com'
    user_name = 'Jan Nowak'

    PasswordlessMailer.with(
      token_link: token_link,
      email:      email,
      user_name:  user_name,
    ).token_email
  end
end
