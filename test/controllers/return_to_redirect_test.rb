# frozen_string_literal: true

require 'test_helper'

class ReturnToRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @invite = FactoryBot.create(:story_group_invite, story_group: @story_group)
    @student = FactoryBot.create(:user, role: :student)
  end

  test 'QR link brings the user back to the join page after passwordless login' do
    get join_path(code: @invite.code)
    assert_redirected_to login_path

    verify_login(@student)

    assert_redirected_to join_path(code: @invite.code)
    assert_equal 'Zalogowano pomyślnie.', flash[:notice]
  end

  test 'query string is preserved' do
    get lookup_join_index_path(code: @invite.code)
    assert_redirected_to login_path

    verify_login(@student)

    assert_redirected_to lookup_join_index_path(code: @invite.code)
  end

  test 'without a stored path login lands on home' do
    verify_login(@student)

    assert_redirected_to home_path
  end

  test 'stored path is used only once' do
    get join_path(code: @invite.code)
    verify_login(@student)
    assert_redirected_to join_path(code: @invite.code)

    delete logout_path
    verify_login(@student)

    assert_redirected_to home_path
  end

  test 'non-GET requests are not stored' do
    post join_index_url, params: { code: @invite.code }
    assert_redirected_to login_path

    verify_login(@student)

    assert_redirected_to home_path
  end

  test 'turbo frame requests are not stored' do
    get join_path(code: @invite.code), headers: { 'Turbo-Frame' => 'modal' }
    assert_redirected_to login_path

    verify_login(@student)

    assert_redirected_to home_path
  end

  test 'bypass login honours the stored path' do
    BypassLoginService.any_instance.stubs(:can_bypass_login?).returns(true)

    get join_path(code: @invite.code)
    post auth_passwordless_path, params: { email: @student.email }

    assert_redirected_to join_path(code: @invite.code)
  end

  test 'USOS callback honours the stored path' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:uam_usos] = OmniAuth::AuthHash.new(provider: 'uam_usos', uid: '1')
    Providers::UsosAdapter.stubs(:new).returns(stub)
    SessionUserBuilder.any_instance.stubs(:build).returns(@student)

    get join_path(code: @invite.code)
    get auth_callback_path(provider: 'uam_usos')

    assert_redirected_to join_path(code: @invite.code)
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:uam_usos)
  end

  private

  def verify_login(user)
    get auth_passwordless_verify_path(token: user.create_login_token!.raw_token)
  end
end
