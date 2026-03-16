# frozen_string_literal: true

class SessionsController < ApplicationController
  BASE_ALLOWED_PROVIDERS = %w[uam_usos].freeze

  skip_before_action :authenticate!, only: %i[new create]
  before_action :validate_provider!, only: :create

  def new; end

  def create
    auth = request.env['omniauth.auth']
    builder = SessionBuilder.new(auth, @provider)
    session_data = builder.build
    session[:user] = session_data

    redirect_to home_path
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  private

  def validate_provider!
    allowed_providers = BASE_ALLOWED_PROVIDERS.dup
    allowed_providers << 'development' unless Rails.env.production?

    @provider = params['provider']
    redirect_to root_path, alert: 'Invalid provider' unless allowed_providers.include?(@provider)
  end
end
