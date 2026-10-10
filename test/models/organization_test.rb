# frozen_string_literal: true

require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  test 'requires max_members' do
    organization = FactoryBot.build(:organization, max_members: nil)

    assert_not organization.valid?
    assert organization.errors.added?(:max_members, :blank)
  end

  test 'requires positive max_members' do
    organization = FactoryBot.build(:organization, max_members: 0)

    assert_not organization.valid?
  end

  test 'full? when members count reaches max_members' do
    organization = FactoryBot.create(:organization, max_members: 1)
    assert_not organization.full?

    FactoryBot.create(:user, organization: organization)
    assert organization.full?
  end

  test 'cannot lower max_members below current members count' do
    organization = FactoryBot.create(:organization, max_members: 2)
    FactoryBot.create_list(:user, 2, organization: organization)

    organization.max_members = 1
    assert_not organization.valid?
    assert_includes organization.errors[:max_members], "can't be lower than the current number of members (2)"
  end

  test 'requires unique name' do
    FactoryBot.create(:organization, name: 'Example university')
    organization = FactoryBot.build(:organization, name: 'Example university')

    assert_not organization.valid?
    assert organization.errors[:name].any?
  end
end
