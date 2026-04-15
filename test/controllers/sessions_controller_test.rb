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

  test 'redirect to login path if not logged in' do
    delete logout_path
    assert_redirected_to login_path
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
