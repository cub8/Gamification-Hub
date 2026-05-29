# frozen_string_literal: true

class Auth::PasswordlessController < ApplicationController
  include LoggedUserRedirector

  layout 'public'

  skip_before_action :authenticate!
  before_action :redirect_logged_user

  def new; end

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

    redirect_to new_auth_passwordless_path, notice: 'Wysłaliśmy na Twój adres email link logujący!'
  end

  private

  def bypass_login(user)
    reset_session
    session[:user_id] = user.id
    redirect_to home_path, notice: 'Zalogowano pomyślnie.'
  end
end
