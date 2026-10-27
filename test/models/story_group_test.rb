# frozen_string_literal: true

require 'test_helper'

class StoryGroupTest < ActiveSupport::TestCase
  test 'name too long' do
    story_group = StoryGroup.new(name:          'My name is extremely long and most likely, or atleast i
                                  hope it will not pass this test',
                                 description:   'Just a regular description',
                                 currency_name: 'Polski złoty',)

    assert_equal true, story_group.invalid?
    assert_equal true, story_group.errors[:name].any?
  end

  test 'a group with purchases can be destroyed, notifications included' do
    story_group = FactoryBot.create(:story_group)
    student     = FactoryBot.create(:story_group_student, story_group: story_group, user: FactoryBot.create(:user))
    item        = FactoryBot.create(:item, story_group: story_group)
    notification = FactoryBot.create(:notification, story_group: story_group, story_group_student: student,
                                                    item:        item,)

    story_group.destroy!

    assert_not Notification.exists?(notification.id)
  end
end
