# frozen_string_literal: true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'global admin gets the organizations overview' do
    FactoryBot.create(:organization, name: 'Uniwersytet Testowy')
    sign_in FactoryBot.create(:user, :global_admin)

    get home_url

    assert_response :success
    assert_select '.gh-start-org-row', text: /Uniwersytet Testowy/
    assert_select '.gh-todo-card', text: /Brak administratora/
  end

  test 'global admin without organizations gets the empty state' do
    sign_in FactoryBot.create(:user, :global_admin)

    get home_url

    assert_response :success
    assert_select '.gh-empty-state', text: /pierwszej organizacji/
  end

  test 'organization admin gets their organization overview' do
    organization = FactoryBot.create(:organization, max_members: 10)
    FactoryBot.create(:user, :student, organization: organization, full_name: 'Jan Nowak')
    sign_in FactoryBot.create(:user, :organization_admin, organization: organization)

    get home_url

    assert_response :success
    assert_select '.gh-page-kicker', text: organization.name
    assert_select '.gh-start-org-row', text: /Jan Nowak/
  end

  test 'organization admin without organization sees a notice' do
    sign_in FactoryBot.create(:user, :organization_admin)

    get home_url

    assert_response :success
    assert_select '.gh-empty-state', text: /nie jest przypisane/
  end

  test 'global admin sidebar has no story groups' do
    admin = FactoryBot.create(:user, :global_admin)
    FactoryBot.create(:story_group, owner: admin, name: 'Grupa admina')
    sign_in admin

    get home_url

    assert_select '.gh-sidebar-link', text: 'Organizacje'
    assert_select '.gh-sidebar-link', text: 'Grupy', count: 0
    assert_select '.gh-sidebar-group-list', count: 0
  end
end
