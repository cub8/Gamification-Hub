# frozen_string_literal: true

class SessionsController < ApplicationController
  class InvalidProviderError < StandardError; end

  skip_before_action :authenticate!, only: %i[new create]
  before_action :redirect_logged_user, only: %i[new create]

  def new; end

  def create
    provider = find_provider
    builder = SessionUserBuilder.new(provider)
    user = builder.build

    session[:user_id] = user.id

    redirect_to home_path
  rescue InvalidProviderError
    redirect_to root_path, alert: 'Invalid provider.'
  rescue Providers::InvalidAuthError
    redirect_to root_path, alert: 'Invalid authorization attempt.'
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  private

  def redirect_logged_user
    redirect_to root_path, alert: 'Already logged in' if @current_user
  end

  def find_provider
    case params['provider']
    when 'uam_usos'
      auth = request.env['omniauth.auth']
      Providers::UsosAdapter.new(auth)
    when 'development'
      permitted = %i[email full_name university_name university_number]
      permitted << :role unless Rails.env.production?
      auth = params.permit(permitted)

      Providers::DevelopmentAdapter.new(auth)
    else
      raise InvalidProviderError
    end
  end
end
