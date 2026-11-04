# frozen_string_literal: true

require 'test_helper'

class Auth::UsosControllerTest < ActionDispatch::IntegrationTest
  test 'failed USOS login redirects to login with an alert instead of 404' do
    get auth_failure_path(message: 'invalid_credentials', strategy: 'uam_usos')

    assert_redirected_to login_path
    assert_equal I18n.t('auth.flash.usos_failure'), flash[:alert]
  end
end
