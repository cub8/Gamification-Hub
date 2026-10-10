# frozen_string_literal: true

require 'test_helper'

class GlobalAdminStartDashboardTest < ActiveSupport::TestCase
  setup do
    @full = FactoryBot.create(:organization, name: 'Pełna', max_members: 2)
    FactoryBot.create(:user, :organization_admin, organization: @full)
    FactoryBot.create(:user, :student, organization: @full)

    @orphan = FactoryBot.create(:organization, name: 'Bez admina', max_members: 10)
    FactoryBot.create(:user, :student, organization: @orphan)

    @fine = FactoryBot.create(:organization, name: 'W porządku', max_members: 10)
    FactoryBot.create(:user, :organization_admin, organization: @fine, first_login: true)
  end

  test 'summarizes every organization' do
    dashboard = GlobalAdminStartDashboard.new.load

    names = dashboard.organizations.map { |org| org.organization.name }
    assert_equal ['Bez admina', 'Pełna', 'W porządku'], names
    assert_equal [3, 4, 18, 1], dashboard.stat_tiles.map(&:value)
  end

  test 'flags organizations without admin and nearly full ones' do
    dashboard = GlobalAdminStartDashboard.new.load

    assert_equal [@orphan], dashboard.without_admin.map(&:organization)
    assert_equal [@full], dashboard.nearly_full.map(&:organization)
    assert dashboard.attention?
  end

  test 'fill level' do
    org = GlobalAdminStartDashboard.new.load.organizations.find { |o| o.organization == @full }

    assert_equal 100, org.fill_percent
    assert org.full?
    assert_equal 0, org.free
  end
end
