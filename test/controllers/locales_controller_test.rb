# frozen_string_literal: true

require 'test_helper'

class LocalesControllerTest < ActionDispatch::IntegrationTest
  test 'renders in Polish by default' do
    get login_path

    assert_select 'html[lang=pl]'
  end

  test 'uses browser language when no locale was chosen' do
    get login_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9,pl;q=0.8' }

    assert_select 'html[lang=en]'
  end

  test 'falls back to Polish for unsupported browser language' do
    get login_path, headers: { 'Accept-Language' => 'de-DE,de;q=0.9' }

    assert_select 'html[lang=pl]'
  end

  test 'switches locale and redirects back' do
    patch locale_path, params: { locale: 'en' }, headers: { 'HTTP_REFERER' => login_url }

    assert_redirected_to login_url
    assert_equal 'en', cookies[:locale]

    get login_path
    assert_select 'html[lang=en]'
  end

  test 'chosen locale wins over browser language' do
    patch locale_path, params: { locale: 'pl' }

    get login_path, headers: { 'Accept-Language' => 'en-US,en;q=0.9' }
    assert_select 'html[lang=pl]'
  end

  test 'ignores unsupported locale' do
    patch locale_path, params: { locale: 'de' }

    assert_redirected_to root_path
    assert_nil cookies[:locale]
  end

  test 'logged in user can switch locale' do
    sign_in FactoryBot.create(:user, :student)

    patch locale_path, params: { locale: 'en' }, headers: { 'HTTP_REFERER' => home_url }

    assert_redirected_to home_url
    get home_path
    assert_select 'html[lang=en]'
  end
end
