# frozen_string_literal: true

class Auth::PasswordlessController < ApplicationController
  include Auth::SignIn
  include LoggedUserRedirector

  RESEND_COOLDOWN = 60

  skip_before_action :authenticate!
  before_action :redirect_logged_user
  before_action -> { @chrome = false }, only: %i[new inbox]
  before_action :clear_pending_login, only: :new

  def new; end

  def inbox
    @email = session[:pending_login_email]
    sent_at = session[:pending_login_sent_at].to_i
    current_time = Time.current.to_i

    return redirect_to new_auth_passwordless_path if @email.blank? || sent_at.zero?
    return redirect_to new_auth_passwordless_path if current_time - sent_at > LoginToken::EXPIRES_IN

    delta = current_time - sent_at

    @cooldown = [RESEND_COOLDOWN - delta, 0].max
  end

  def verify
    token = params.expect(:token)
    login_token = LoginToken.find_by_token(token)

    return redirect_to login_path, alert: 'Nieprawidłowy token' if login_token.nil? || login_token.expired?

    user = login_token.user
    user.consume_login_token!

    sign_in_and_redirect(user)
  end

  def create
    email = params.expect(:email)
    user = User.find_by(email: email)
    service = BypassLoginService.new(email: email)

    resend = session[:pending_login_email].present?

    if user
      return sign_in_and_redirect(user) if service.can_bypass_login?

      token = user.create_login_token!
      token_link = auth_passwordless_verify_url(token: token.raw_token)

      PasswordlessMailer.with(
        token_link: token_link,
        email:      email,
        user_name:  user.full_name,
      ).token_email.deliver_later
    end

    session[:pending_login_email]   = email
    session[:pending_login_sent_at] = Time.current.to_i

    notice = 'Wysłaliśmy nowy link. Poprzedni już nie działa.' if resend
    redirect_to auth_passwordless_inbox_path, notice: notice
  end

  private

  def clear_pending_login
    session.delete(:pending_login_email)
    session.delete(:pending_login_sent_at)
  end
end
