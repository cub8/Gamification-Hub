# frozen_string_literal: true

module LoggedUserRedirector
  def redirect_logged_user
    redirect_to root_path, alert: 'Already logged in' if @current_user
  end
end
