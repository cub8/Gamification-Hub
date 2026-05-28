# frozen_string_literal: true

class NotificationsController < ApplicationController
  def index
    @notifications =
      current_user.notifications
                  .includes(:item, story_group: { icon_attachment: :blob }, story_group_student: :user)
                  .order(created_at: :desc)

    @unread = @notifications.unread
    @read = @notifications.read
  end

  def mark_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    render turbo_stream: turbo_stream.remove('notification-dot')
  end
end
