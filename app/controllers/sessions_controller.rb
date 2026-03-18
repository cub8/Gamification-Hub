# frozen_string_literal: true

class SessionsController < ApplicationController
  BASE_ALLOWED_PROVIDERS = %w[uam_usos].freeze

  skip_before_action :authenticate!, only: %i[new create]
  before_action :redirect_logged_user, only: %i[new create]
  before_action :validate_provider!, only: :create

  def new; end

  def create
    builder = UserBuilder.new(retrieve_auth, @provider)
    user = builder.build

    session[:user_id] = user.id

    redirect_to home_path
  rescue UserBuilder::InvalidAuthError
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

  def validate_provider!
    allowed_providers = BASE_ALLOWED_PROVIDERS.dup
    allowed_providers << 'development' unless Rails.env.production?

    @provider = params['provider']
    redirect_to root_path, alert: 'Invalid provider' unless allowed_providers.include?(@provider)
  end

  def retrieve_auth
    return params.permit(:email, :full_name, :role, :university_name, :university_number) if @provider == 'development'

    request.env['omniauth.auth']
  end
end
