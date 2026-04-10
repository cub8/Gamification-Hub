# frozen_string_literal: true

require 'test_helper'

class RootControllerTest < ActionDispatch::IntegrationTest
  test 'should redirect to home view if logged in' do
    user = FactoryBot.create(:user)
    login_token = user.create_login_token!
    get auth_passwordless_verify_path(token: login_token.token)

    get root_path
    assert_redirected_to home_path
  end

  test 'should redirect to home view if not logged in' do
    get root_path
    assert_redirected_to login_path
  end
end
