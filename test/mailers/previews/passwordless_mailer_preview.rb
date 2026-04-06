# Preview all emails at http://localhost:3000/rails/mailers/passwordless_mailer
class PasswordlessMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/passwordless_mailer/token_email
  def token_email
    PasswordlessMailer.token_email
  end
end
