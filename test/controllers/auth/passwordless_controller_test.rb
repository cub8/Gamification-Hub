# frozen_string_literal: true

require 'test_helper'

class Auth::PasswordlessControllerTest < ActionDispatch::IntegrationTest
  test '#new - not logged user can access view' do
    get new_auth_passwordless_path
    assert_response :success
  end

  test '#new - logged user cant access new view' do
    user = FactoryBot.create(:user)
    sign_in user
    get new_auth_passwordless_path
    assert_redirected_to root_path
  end

  test '#create - sends an email if user exists' do
    user = FactoryBot.create(:user)

    assert_enqueued_emails 1 do
      post auth_passwordless_path, params: { email: user.email }
    end

    assert_redirected_to new_auth_passwordless_path
    assert_equal 'Wysłaliśmy na Twój adres email link logujący!', flash[:notice]
  end

  test '#create - does not send an email if user does not exist' do
    assert_nil User.find_by(email: 'test@example.com')

    assert_no_enqueued_emails do
      post auth_passwordless_path, params: { email: 'test@example.com' }
    end

    assert_redirected_to new_auth_passwordless_path
    assert_equal 'Wysłaliśmy na Twój adres email link logujący!', flash[:notice]
  end

  test '#verify - sign in with valid token' do
    user = FactoryBot.create(:user)
    login_token = user.create_login_token!

    get auth_passwordless_verify_path(token: login_token.token)
    assert_redirected_to home_path
    assert_equal 'Zalogowano pomyślnie.', flash[:notice]
  end

  test '#verify - cant sign in with same token twice' do
    user = FactoryBot.create(:user)
    login_token = user.create_login_token!

    get auth_passwordless_verify_path(token: login_token.token)
    assert_redirected_to home_path
    assert_equal 'Zalogowano pomyślnie.', flash[:notice]

    assert_nil user.reload.login_token

    delete logout_path
    get auth_passwordless_verify_path(token: login_token.token)
    assert_redirected_to login_path
    assert_equal 'Nieprawidłowy token', flash[:alert]
  end

  test '#verify - cant sign in if invalid token' do
    assert_nil LoginToken.find_by(token: '123456')

    get auth_passwordless_verify_path(token: '123456')
    assert_redirected_to login_path
    assert_equal 'Nieprawidłowy token', flash[:alert]
  end
end
