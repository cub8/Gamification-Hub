# frozen_string_literal: true

require 'test_helper'

class OrganizationAdminStartDashboardTest < ActiveSupport::TestCase
  setup do
    @organization = FactoryBot.create(:organization, max_members: 10)
    @admin = FactoryBot.create(:user, :organization_admin, organization: @organization)
    @student = FactoryBot.create(:user, :student, organization: @organization)
    @invited = FactoryBot.create(:user, :teacher, organization: @organization, first_login: true)
  end

  test 'counts members by role and free seats' do
    dashboard = OrganizationAdminStartDashboard.new(user: @admin).load

    assert_equal [1, 1, 7, 1], dashboard.stat_tiles.map(&:value)
    assert_equal 30, dashboard.fill_percent
    assert_not dashboard.full?
  end

  test 'lists recent and pending users without admins' do
    dashboard = OrganizationAdminStartDashboard.new(user: @admin).load

    assert_equal [@invited, @student], dashboard.recent_users
    assert_equal [@invited], dashboard.pending_users
  end

  test 'handles an admin without organization' do
    admin = FactoryBot.create(:user, :organization_admin)

    assert_nil OrganizationAdminStartDashboard.new(user: admin).load.organization
  end
end
