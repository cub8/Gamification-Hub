# frozen_string_literal: true

require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher_user = FactoryBot.create(:user, role: :teacher)
    @other_user = FactoryBot.create(:user, role: :teacher)

    @story_group = FactoryBot.create(:story_group, owner_id: @teacher_user.id)
    @student_user = FactoryBot.create(:user, role: :student)
    @student = FactoryBot.create(:story_group_student, story_group: @story_group, user: @student_user)
    @item = FactoryBot.create(:item, story_group: @story_group)

    @unread_notification = FactoryBot.create(
      :notification,
      user:                @teacher_user,
      story_group:         @story_group,
      story_group_student: @student,
      item:                @item,
    )

    @read_notification = FactoryBot.create(
      :notification,
      user:                @teacher_user,
      story_group:         @story_group,
      story_group_student: @student,
      item:                @item,
      read_at:             1.day.ago,
    )

    @other_user_notification = FactoryBot.create(
      :notification,
      user:                @other_user,
      story_group:         @story_group,
      story_group_student: @student,
      item:                @item,
    )
  end

  test 'should mark unread notifications as read' do
    sign_in @teacher_user

    assert_nil @unread_notification.read_at
    assert_not_nil @read_notification.read_at
    assert_nil @other_user_notification.read_at

    post mark_as_read_notifications_path
    assert_response :success

    @unread_notification.reload
    @other_user_notification.reload

    assert_not_nil @unread_notification.read_at
    assert_nil @other_user_notification.read_at
  end
end
