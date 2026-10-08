# frozen_string_literal: true

module ::Authentication
  extend ::ActiveSupport::Concern

  included do
    before_action :set_current_user
    before_action :authenticate!
  end

  protected

  attr_reader :current_user

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticate!
    return if @current_user

    store_return_path
    redirect_to login_path, alert: 'Zaloguj się, aby kontynuować.'
  end

  def store_return_path
    session[:return_to] = request.fullpath if full_page_navigation?
  end

  def full_page_navigation?
    request.get? && !request.xhr? && !turbo_frame_request?
  end
end
