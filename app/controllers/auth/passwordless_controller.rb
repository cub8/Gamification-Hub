# frozen_string_literal: true

class Auth::PasswordlessController < ApplicationController
  include LoggedUserRedirector

  # How long the "Wyślij ponownie" button stays disabled on the inbox screen.
  # Presentational only — the real limit is the Rack::Attack throttle on
  # POST /auth/passwordless (config/initializers/rack_attack.rb).
  RESEND_COOLDOWN = 60

  skip_before_action :authenticate!
  before_action :redirect_logged_user
  before_action -> { @chrome = false }, only: %i[new inbox]
  before_action :clear_pending_login, only: :new

  def new; end

  def inbox
    @email = session[:pending_login_email]
    sent_at = session[:pending_login_sent_at].to_i

    # No pending send, or one old enough that its link has already expired.
    return redirect_to new_auth_passwordless_path if @email.blank? || sent_at.zero?
    return redirect_to new_auth_passwordless_path if Time.current.to_i - sent_at > LoginToken::EXPIRES_IN

    @cooldown = [RESEND_COOLDOWN - (Time.current.to_i - sent_at), 0].max
  end

  def verify
    token = params.expect(:token)
    login_token = LoginToken.find_by_token(token)

    return redirect_to login_path, alert: 'Nieprawidłowy token' if login_token.nil? || login_token.expired?

    user = login_token.user
    user.consume_login_token!

    reset_session
    session[:user_id] = user.id

    redirect_to home_path, notice: 'Zalogowano pomyślnie.'
  end

  def create
    email = params.expect(:email)
    user = User.find_by(email: email)
    service = BypassLoginService.new(email: email)

    # Whether this is a resend depends only on prior session state, never on
    # whether the address exists — so it cannot be used to enumerate accounts.
    resend = session[:pending_login_email].present?

    if user
      return bypass_login(user) if service.can_bypass_login?

      token = user.create_login_token!
      token_link = auth_passwordless_verify_url(token: token.raw_token)

      PasswordlessMailer.with(
        token_link: token_link,
        email:      email,
        user_name:  user.full_name,
      ).token_email.deliver_later
    end

    # Everything below MUST stay outside the `if user` block: a known and an
    # unknown address have to produce byte-identical responses. Do not move
    # these next to the mailer call.
    session[:pending_login_email]   = email
    session[:pending_login_sent_at] = Time.current.to_i

    # No notice on a first send — the inbox screen is itself the confirmation.
    notice = resend ? 'Wysłaliśmy nowy link. Poprzedni już nie działa.' : nil
    redirect_to auth_passwordless_inbox_path, notice: notice
  end

  private

  def clear_pending_login
    session.delete(:pending_login_email)
    session.delete(:pending_login_sent_at)
  end

  def bypass_login(user)
    reset_session
    session[:user_id] = user.id
    redirect_to home_path, notice: 'Zalogowano pomyślnie.'
  end
end
