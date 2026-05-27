# frozen_string_literal: true

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @story_group = FactoryBot.create(:story_group, owner_id: @user.id)
    @student_user = FactoryBot.create(:user, role: :student)
    @student = FactoryBot.create(:story_group_student, story_group: @story_group, user: @student_user)
    @item = FactoryBot.create(:item, story_group: @story_group)
  end

  test 'is valid with all required associations' do
    notification = Notification.new(
      user:                @user,
      story_group:         @story_group,
      story_group_student: @student,
      item:                @item,
    )

    assert notification.valid?
  end

  test 'is invalid without required associations' do
    notification = Notification.new

    refute notification.valid?
    assert_not_empty notification.errors[:user]
    assert_not_empty notification.errors[:story_group]
    assert_not_empty notification.errors[:story_group_student]
    assert_not_empty notification.errors[:item]
  end

  test 'unread scope returns only notifications without read_at timestamp' do
    unread_notification = FactoryBot.create(:notification,
                                            user:                @user,
                                            story_group:         @story_group,
                                            story_group_student: @student,
                                            item:                @item,)

    read_notification = FactoryBot.create(:notification,
                                          user:                @user,
                                          story_group:         @story_group,
                                          story_group_student: @student,
                                          item:                @item,
                                          read_at:             Time.current,)

    assert_includes Notification.unread, unread_notification
    refute_includes Notification.unread, read_notification
  end
end
