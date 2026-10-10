# frozen_string_literal: true

require 'test_helper'

class NavigationTest < ActiveSupport::TestCase
  test 'global admin gets the organizations list' do
    user = FactoryBot.create(:user, :global_admin)

    assert_equal %w[Start Organizacje], Navigation.new(user).primary_items.map(&:label)
    assert_equal '/organizations', Navigation.new(user).primary_items.last.path
  end

  test 'organization admin gets their own organization' do
    organization = FactoryBot.create(:organization, max_members: 5)
    user = FactoryBot.create(:user, :organization_admin, organization: organization)

    item = Navigation.new(user).primary_items.last
    assert_equal organization.name, item.label
    assert_equal "/organizations/#{organization.id}", item.path
  end

  test 'other users get no organization item' do
    user = FactoryBot.create(:user, :student)

    assert_equal %w[Start Grupy], Navigation.new(user).primary_items.map(&:label)
  end
end
