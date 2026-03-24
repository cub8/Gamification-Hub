# frozen_string_literal: true

require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'login page - redirect to home path if logged in' do
    user = FactoryBot.create(:user, :student)
    sign_in user

    get login_path
    follow_redirect!
    assert_redirected_to home_path
  end

  test 'auth callback - redirect to home path if logged in' do
    user = FactoryBot.create(:user, :student)
    sign_in user

    get auth_callback_path('development')
    follow_redirect!
    assert_redirected_to home_path
  end

  test 'redirect to login path if not logged in' do
    delete logout_path
    assert_redirected_to login_path
  end

  test 'auth callback - redirect to root if invalid provider' do
    get auth_callback_path('invalid_provider')
    assert_redirected_to root_path
    assert_equal 'Invalid provider.', flash[:alert]
  end

  test 'auth callback - redirect to root if invalid auth, e.g. empty auth' do
    get auth_callback_path('development')
    assert_redirected_to root_path
    assert_equal 'Invalid authorization attempt.', flash[:alert]
  end

  test 'should logout user' do
    user = FactoryBot.create(:user, :student)
    sign_in user

    get home_path
    assert_response :success

    delete logout_path
    assert_redirected_to root_path

    get home_path
    assert_redirected_to login_path
  end
end
