# frozen_string_literal: true

class Auth::PasswordlessController < ApplicationController
  include LoggedUserRedirector

  skip_before_action :authenticate!
  before_action :redirect_logged_user

  def new; end

  def verify
    token = params.expect(:token)
    login_token = LoginToken.find_by(token: token)

    return redirect_to login_path, alert: 'Nieprawidłowy token' if login_token.nil? || login_token.expired?

    user = login_token.user
    session[:user_id] = user.id
    redirect_to home_path
  end

  def create
    email = params.expect(:email)
    user = User.find_by(email: email)

    if user
      token = user.create_login_token!
      token_link = auth_passwordless_verify_url(token: token.token)

      PasswordlessMailer.with(
        token_link: token_link,
        email:      email,
        user_name:  user.full_name,
      ).token_email.deliver_later
    end

    redirect_to new_auth_passwordless_path, notice: 'Wysłaliśmy na Twój adres email link logujący!'
  end
end
