# frozen_string_literal: true

# Redesign header: logo, join, theme, notifications, account.
#
# Ported from design/mockup-src/js-expanded/10-core.js:155 (`header()`), minus
# the two in-group pieces — the group switcher `.gsw` and the student balance
# chip `.bal` both render only when `inGroup()` is true, and no group screen is
# on this layout yet.
class Shared::Redesign::HeaderComponent < ViewComponent::Base
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  private

  def unread_count
    @unread_count ||= user.notifications.unread.count
  end

  def bell_label
    return 'Powiadomienia' if unread_count.zero?

    "Powiadomienia, #{unread_count} #{helpers.gh_plural(unread_count, 'nowe', 'nowe', 'nowych')}"
  end
end
