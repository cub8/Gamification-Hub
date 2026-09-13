# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :story_group
  belongs_to :story_group_student
  belongs_to :item

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  after_create_commit -> {
    broadcast_update_to(
      user,
      :notifications,
      target: 'notification-dot-container',
      html:   "<div class='notification-dot rounded-circle position-absolute' id='notification-dot'></div>".html_safe,
    )

    # The redesign header has its own container: the broadcast above injects
    # Bootstrap-classed markup, which would render unstyled there. Turbo
    # ignores a target that is not on the page, so each layout picks up only
    # the update meant for it.
    broadcast_update_to(
      user,
      :notifications,
      target:  'gh-notification-dot',
      partial: 'layouts/redesign/notification_dot',
      locals:  { count: user.notifications.unread.count },
    )

    broadcast_prepend_to(
      user,
      :notifications,
      target:  'unread-notifications-list',
      partial: 'notifications/notification',
      locals:  { notification: self },
    )
  }
end
