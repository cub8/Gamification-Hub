# frozen_string_literal: true

class PasswordlessMailerPreview < ActionMailer::Preview
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
