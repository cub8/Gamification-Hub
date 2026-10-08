# frozen_string_literal: true

class Auth::UsosController < ApplicationController
  class InvalidProviderError < StandardError; end

  include Authentication
  include Auth::SignIn

  skip_before_action :authenticate!
  before_action :redirect_logged_user

  def create
    provider = find_provider
    builder = SessionUserBuilder.new(provider)
    user = builder.build

    sign_in_and_redirect(user)
  rescue InvalidProviderError
    redirect_to root_path, alert: 'Nieprawidłowy dostawca logowania.'
  rescue Providers::InvalidAuthError
    redirect_to root_path, alert: 'Nieprawidłowa próba autoryzacji.'
  end

  private

  def find_provider
    case params['provider']
    when 'uam_usos'
      auth = request.env['omniauth.auth']
      Providers::UsosAdapter.new(auth)
    else
      raise InvalidProviderError
    end
  end
end
