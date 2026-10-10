# frozen_string_literal: true

require 'test_helper'

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = FactoryBot.create(:user, role: :global_admin)
    sign_in @user
    @organization = FactoryBot.create(:organization)
  end

  test 'should get index' do
    get organizations_url
    assert_response :success
  end

  test 'should get show' do
    get organization_url(@organization)
    assert_response :success
  end

  test 'should get new' do
    get new_organization_url
    assert_response :success
  end

  test 'should get edit' do
    get edit_organization_url(@organization)
    assert_response :success
  end

  test '#add_admin - creates org admin and sends invitation email' do
    assert_difference 'User.count', 1 do
      assert_enqueued_emails 1 do
        post add_admin_organization_url(@organization),
             params:  { user: { email: 'admin@example.com', full_name: 'Anna Kowalska' } },
             headers: { 'Turbo-Frame' => 'modal' }
      end
    end

    assert_turbo_redirected_to organization_url(@organization)

    admin = User.find_by(email: 'admin@example.com')
    assert admin.organization_admin?
    assert admin.first_login?
    assert_equal @organization, admin.organization
    assert admin.login_token.expires_at > 6.days.from_now
  end

  test '#add_admin - does not create admin without email' do
    assert_no_difference 'User.count' do
      assert_no_enqueued_emails do
        post add_admin_organization_url(@organization), params: { user: { email: '', full_name: 'Anna' } }
      end
    end

    assert_response :unprocessable_content
  end

  test '#add_admin - does not create admin when organization is full' do
    FactoryBot.create(:user, organization: @organization)

    assert_no_difference 'User.count' do
      assert_no_enqueued_emails do
        post add_admin_organization_url(@organization), params: { user: { email: 'admin@example.com' } }
      end
    end

    assert_response :unprocessable_content
  end

  test '#add_admin - non global admin cannot add admin' do
    sign_out
    sign_in FactoryBot.create(:user, :organization_admin, organization: @organization)

    assert_no_difference 'User.count' do
      post add_admin_organization_url(@organization), params: { user: { email: 'admin@example.com' } }
    end

    assert_redirected_to root_path
  end

  test '#add_user - creates user with selected role' do
    assert_difference 'User.count', 1 do
      post add_user_organization_url(@organization),
           params: { user: { email: 'teacher@example.com', full_name: 'Jan Nowak', role: 'teacher' } }
    end

    assert User.find_by(email: 'teacher@example.com').teacher?
  end

  test '#add_user - does not create user with admin role' do
    %w[organization_admin global_admin].each do |role|
      assert_no_difference 'User.count' do
        assert_no_enqueued_emails do
          post add_user_organization_url(@organization),
               params: { user: { email: 'evil@example.com', full_name: 'Jan Nowak', role: role } }
        end
      end

      assert_response :unprocessable_content
    end
  end

  test '#show - global admin sees admins and capacity' do
    FactoryBot.create(:user, :organization_admin, organization: @organization, full_name: 'Anna Kowalska')

    get organization_url(@organization)

    assert_response :success
    assert_select '.gh-organization-member-row', text: /Anna Kowalska/
    assert_select '.gh-lead', text: /1 z #{@organization.max_members} miejsc/
  end

  test '#destroy - requires the organization name to be typed' do
    assert_no_difference 'Organization.count' do
      delete organization_url(@organization), params: { confirm: 'wrong name' }
    end

    assert_response :unprocessable_content
  end

  test '#destroy - deletes organization when name matches' do
    assert_difference 'Organization.count', -1 do
      delete organization_url(@organization), params: { confirm: @organization.name }
    end

    assert_redirected_to organizations_url
  end
end
