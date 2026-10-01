# frozen_string_literal: true

# App header: logo, balance, join, theme, notifications, account.
#
# The group switcher `.gsw` renders only inside a group and only below
# 720px, where the sidebar and its deck are gone; the balance chip
# `.gh-balance-button` renders inside a group for anyone enrolled in it.
class Shared::HeaderComponent < ViewComponent::Base
  attr_reader :user, :group_chrome

  def initialize(user:, group_chrome: nil)
    @user = user
    @group_chrome = group_chrome
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
