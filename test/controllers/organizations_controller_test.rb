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
end
