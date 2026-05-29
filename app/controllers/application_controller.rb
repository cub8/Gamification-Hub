# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  attr_reader :current_user

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_user
  before_action :authenticate!
  before_action :set_sidebar_state

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  protected

  def redirect_outside_turbo_frame(path, notice: nil, alert: nil)
    flash[:notice] = notice if notice
    fash[:alert] = alert if alert

    render turbo_stream: turbo_stream.action(:redirect, path)
  end

  def set_sidebar_state
    @sidebar_collapsed = cookies[:sidebar_collapsed] == 'true'
  end

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticate!
    redirect_to login_path, alert: 'Please log in before continuing.' unless @current_user
  end

  def record_not_found
    redirect_to root_path, alert: 'Not found'
  end

  def not_authorized
    redirect_to root_path, alert: 'Not found'
  end
end
