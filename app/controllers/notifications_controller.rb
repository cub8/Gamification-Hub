# frozen_string_literal: true

class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.includes(:story_group, :item,
                                                         story_group_student: :user,).order(created_at: :desc)
    current_user.notifications.unread.update_all(read_at: Time.current)
  end
end
