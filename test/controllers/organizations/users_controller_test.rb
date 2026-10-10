# frozen_string_literal: true

require 'test_helper'

class Organizations::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = FactoryBot.create(:organization, max_members: 10)
    @admin = FactoryBot.create(:user, :organization_admin, organization: @organization)
    @student = FactoryBot.create(:user, :student, organization: @organization, full_name: 'Jan Nowak')
    sign_in @admin
  end

  test 'org admin sees users table on organization page' do
    get organization_url(@organization)

    assert_response :success
    assert_select "#user_#{@student.id}"
    assert_select "#user_#{@admin.id}", count: 0
  end

  test '#edit - renders form' do
    get edit_organization_user_url(@organization, @student)
    assert_response :success
  end

  test '#update - updates user' do
    patch organization_user_url(@organization, @student),
          params:  { user: { full_name: 'Jan Kowalski', role: 'teacher' } },
          headers: { 'Turbo-Frame' => 'modal' }

    assert_turbo_redirected_to organization_url(@organization)
    @student.reload
    assert_equal 'Jan Kowalski', @student.full_name
    assert @student.teacher?
  end

  test '#update - cannot promote user to admin' do
    patch organization_user_url(@organization, @student), params: { user: { role: 'global_admin' } }

    assert_response :unprocessable_content
    assert @student.reload.student?
  end

  test '#confirm_destroy - renders confirmation' do
    get confirm_destroy_organization_user_url(@organization, @student)
    assert_response :success
  end

  test '#destroy - removes user' do
    assert_difference 'User.count', -1 do
      delete organization_user_url(@organization, @student)
    end

    assert_redirected_to organization_url(@organization)
  end

  test 'cannot edit or destroy an admin' do
    other_admin = FactoryBot.create(:user, :organization_admin, organization: @organization)

    assert_no_difference 'User.count' do
      delete organization_user_url(@organization, other_admin)
    end
    assert_redirected_to root_path

    patch organization_user_url(@organization, other_admin), params: { user: { role: 'student' } }
    assert other_admin.reload.organization_admin?
  end

  test 'admin of another organization cannot manage users' do
    other_organization = FactoryBot.create(:organization, max_members: 10)
    sign_out
    sign_in FactoryBot.create(:user, :organization_admin, organization: other_organization)

    assert_no_difference 'User.count' do
      delete organization_user_url(@organization, @student)
    end
    assert_redirected_to root_path
  end

  test 'cannot reach a user from another organization through this one' do
    outsider = FactoryBot.create(:user, :student, organization: FactoryBot.create(:organization))

    assert_no_difference 'User.count' do
      delete organization_user_url(@organization, outsider)
    end
    assert_redirected_to root_path
  end
end
