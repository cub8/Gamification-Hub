# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate!

  protected

  def authenticate!
    redirect_to login_path, alert: 'Please log in before continuing.' unless session[:user]
  end
end
