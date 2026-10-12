# frozen_string_literal: true

module Auth::SignIn
  extend ActiveSupport::Concern

  private

  def sign_in_and_redirect(user)
    return_to = session[:return_to]
    reset_session
    session[:user_id] = user.id

    redirect_to after_login_path(return_to), notice: 'Zalogowano pomyślnie.'
  end

  def after_login_path(path)
    return path if local_path?(path)

    home_path
  end

  def local_path?(path)
    path&.start_with?('/') && !path.start_with?('//')
  end
end
