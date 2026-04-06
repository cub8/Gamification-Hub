# frozen_string_literal: true

class Auth::UsosController < ApplicationController
  class InvalidProviderError < StandardError; end

  include LoggedUserRedirector

  skip_before_action :authenticate!
  before_action :redirect_logged_user

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

  private

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
