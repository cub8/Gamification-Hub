# frozen_string_literal: true

class ApplicationController < ActionController::Base
  attr_reader :current_user

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_user
  before_action :authenticate!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticate!
    redirect_to login_path, alert: 'Please log in before continuing.' unless @current_user
  end

  def record_not_found
    redirect_to root_path, alert: 'Not found'
  end
end
