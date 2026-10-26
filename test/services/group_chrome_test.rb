# frozen_string_literal: true

require 'test_helper'

class GroupChromeTest < ActiveSupport::TestCase
  setup do
    @organization = FactoryBot.create(:organization, max_members: 10)
    @owner = FactoryBot.create(:user, :teacher, organization: @organization)
    @story_group = FactoryBot.create(:story_group, owner: @owner)
  end

  test 'organization admin gets the deck for a group in their organization' do
    admin = FactoryBot.create(:user, :organization_admin, organization: @organization)

    chrome = GroupChrome.for(user: admin, story_group: @story_group)

    assert_equal :adm, chrome.role
    assert_equal 'Nadzorujesz tę grupę', chrome.role_label
    assert_includes chrome.items.map(&:label), 'Studenci'
  end

  test 'organization admin gets no deck for another organization' do
    other = FactoryBot.create(:organization, max_members: 10)
    admin = FactoryBot.create(:user, :organization_admin, organization: other)

    assert_nil GroupChrome.for(user: admin, story_group: @story_group)
  end

  test 'owner keeps the owner role' do
    assert_equal :own, GroupChrome.for(user: @owner, story_group: @story_group).role
  end
end
