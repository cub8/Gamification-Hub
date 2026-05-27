# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :story_group
  belongs_to :story_group_student
  belongs_to :item

  scope :unread, -> { where(read_at: nil) }

  after_create_commit -> {
    broadcast_update_to(
      user,
      :notifications,
      target: 'notification-dot-container',
      html:   "<div class='notification-dot rounded-circle position-absolute' id='notification-dot'></div>".html_safe,
    )
  }
end
