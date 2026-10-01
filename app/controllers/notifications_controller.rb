# frozen_string_literal: true

class NotificationsController < ApplicationController
  def index
    load_notifications
  end

  def mark_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    load_notifications

    # The badge is emptied in place, because its container is turbo-permanent.
    # The second stream re-renders the panel, which is open while this runs —
    # without it the rows would keep their "Nowe" heading and unread dots.
    render turbo_stream: [
      turbo_stream.update('gh-notification-dot', ''),
      turbo_stream.update('panel', partial: 'notifications/panel',
                                   locals:  { notifications: @notifications, unread: @unread, read: @read },),
    ]
  end

  private

  def load_notifications
    @notifications =
      current_user.notifications
                  .includes(:item, story_group: { icon_attachment: :blob }, story_group_student: :user)
                  .order(created_at: :desc)

    @unread = @notifications.unread
    @read = @notifications.read
  end
end
