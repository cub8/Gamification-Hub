# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Authentication
  include Sidebar
  include StatusRedirects

  allow_browser versions: :modern

  layout -> { @in_modal ? false : 'application' }

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  protected

  def redirect_outside_turbo_frame(path, notice: nil, alert: nil)
    flash[:notice] = notice if notice
    flash[:alert] = alert if alert

    render turbo_stream: turbo_stream.action(:redirect, path)
  end
end
