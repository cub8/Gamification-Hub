# frozen_string_literal: true

class NotificationsController < ApplicationController
  # The redesign variant of this list uses gh_* helpers. This controller is not
  # on the redesign layout (it only ever answers inside a turbo frame), so it
  # cannot get them from RedesignLayout — `include_all_helpers` is false, so
  # the include has to be explicit.
  helper RedesignHelper

  def index
    load_notifications

    # The redesign header opens notifications in the anchored `panel` dialog;
    # the Bootstrap header loads them into its own `notifications_list` frame.
    # The requesting frame is the only thing that differs, so it is also the
    # cleanest signal for which markup to send back — the same branch
    # students_items/index already uses. `modal` is the centred dialog and
    # stays reserved for forms.
    render 'redesign_index' if turbo_frame_request_id == 'panel'
  end

  def mark_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    load_notifications

    # Each layout keeps its own unread marker, so clear both: the Bootstrap
    # header's dot is removed outright, the redesign header's badge is emptied
    # in place because its container is turbo-permanent. The third stream
    # re-renders the redesign panel, which is open while this runs — without it
    # the rows would keep their "Nowe" heading and unread dots.
    #
    # Turbo ignores a target that is not on the page, so each layout picks up
    # only the streams meant for it.
    render turbo_stream: [
      turbo_stream.remove('notification-dot'),
      turbo_stream.update('gh-notification-dot', ''),
      turbo_stream.update('panel', partial: 'notifications/redesign_panel',
                                   locals:  { notifications: @notifications, unread: @unread, read: @read },),
    ]
  end

  private

  # The item is what the redesign row shows; the group icon is still eager
  # loaded because the Bootstrap partial renders it.
  def load_notifications
    @notifications =
      current_user.notifications
                  .includes(:item, story_group: { icon_attachment: :blob }, story_group_student: :user)
                  .order(created_at: :desc)

    @unread = @notifications.unread
    @read = @notifications.read
  end
end
