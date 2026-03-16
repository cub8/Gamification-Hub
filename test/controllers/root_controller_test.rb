# frozen_string_literal: true

require 'test_helper'

class RootControllerTest < ActionDispatch::IntegrationTest
  test 'should redirect to home view if logged in' do
    get auth_callback_path(provider: 'development')

    get root_path
    assert_redirected_to home_path
  end

  test 'should redirect to home view if not logged in' do
    get root_path
    assert_redirected_to login_path
  end
end
