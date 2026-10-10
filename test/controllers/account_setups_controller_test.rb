# frozen_string_literal: true

require 'test_helper'

class AccountSetupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = FactoryBot.create(:user, :organization_admin, first_login: true, full_name: nil)
  end

  test 'org admin with first login is redirected to account setup' do
    sign_in @admin
    follow_redirect!

    assert_redirected_to edit_account_setup_path
  end

  test 'non admin user with first login is not redirected to account setup' do
    sign_in FactoryBot.create(:user, :student, first_login: true)
    get home_path

    assert_response :success
  end

  test '#edit - renders form' do
    sign_in @admin
    get edit_account_setup_path

    assert_response :success
  end

  test '#edit - user not needing setup is redirected home' do
    sign_in FactoryBot.create(:user, :student, first_login: true)
    get edit_account_setup_path

    assert_redirected_to home_path
  end

  test '#update - saves data and finishes setup' do
    sign_in @admin
    patch account_setup_path, params: { user: { full_name: 'Anna Kowalska' } }

    assert_redirected_to home_path
    @admin.reload
    assert_equal 'Anna Kowalska', @admin.full_name
    assert_not @admin.first_login?
  end

  test '#update - requires full name' do
    sign_in @admin
    patch account_setup_path, params: { user: { full_name: '' } }

    assert_response :unprocessable_content
    assert @admin.reload.first_login?
  end
end
