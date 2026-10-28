# frozen_string_literal: true

require 'test_helper'

class Organizations::AdminsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = FactoryBot.create(:organization, max_members: 10)
    @admin = FactoryBot.create(:user, :organization_admin, organization: @organization, full_name: 'Anna Kowalska')
    sign_in FactoryBot.create(:user, :global_admin)
  end

  test '#confirm_destroy - renders confirmation' do
    get confirm_destroy_organization_admin_url(@organization, @admin)

    assert_response :success
    assert_select 'form[action=?]', organization_admin_path(@organization, @admin)
  end

  test '#destroy - removes the admin and their invitation link' do
    @admin.create_login_token!

    assert_difference -> { User.count } => -1, -> { LoginToken.count } => -1 do
      delete organization_admin_url(@organization, @admin)
    end

    assert_redirected_to organization_url(@organization)
  end

  test '#destroy - keeps currency the admin granted' do
    student = FactoryBot.create(:story_group_student, story_group: FactoryBot.create(:story_group),
                                                      user:        FactoryBot.create(:user, :student),)
    transaction = FactoryBot.create(:currency_transaction, student: student, kind: :adjustment, granted_by_user: @admin)

    delete organization_admin_url(@organization, @admin)

    assert_nil transaction.reload.granted_by_user_id
  end

  test '#destroy - removes the groups the admin owns' do
    story_group = FactoryBot.create(:story_group, owner: @admin, name: 'Chemia')

    get confirm_destroy_organization_admin_url(@organization, @admin)
    assert_select 'form[action=?]', organization_admin_path(@organization, @admin)
    assert_select '.gh-explainer-note b', text: 'Chemia'

    assert_difference 'User.count', -1 do
      delete organization_admin_url(@organization, @admin)
    end
    assert_not StoryGroup.exists?(story_group.id)
  end

  test 'does not remove other roles' do
    student = FactoryBot.create(:user, :student, organization: @organization)

    assert_no_difference 'User.count' do
      delete organization_admin_url(@organization, student)
    end
  end

  test 'organization admin cannot remove admins' do
    sign_out
    sign_in FactoryBot.create(:user, :organization_admin, organization: @organization)

    assert_no_difference 'User.count' do
      delete organization_admin_url(@organization, @admin)
    end
  end

  test 'organization page shows the delete button to global admins only' do
    get organization_url(@organization)
    assert_select "##{ActionView::RecordIdentifier.dom_id(@admin, :admin)} a[href=?]",
                  confirm_destroy_organization_admin_path(@organization, @admin)

    sign_out
    sign_in @admin
    get organization_url(@organization)
    assert_select 'a[href=?]', confirm_destroy_organization_admin_path(@organization, @admin), count: 0
  end
end
