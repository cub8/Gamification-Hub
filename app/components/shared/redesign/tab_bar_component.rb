# frozen_string_literal: true

# Mobile bottom tab bar. Net new — the app has no mobile navigation today.
#
# Ported from design/mockup-src/js-expanded/10-core.js:190 (`tabbar()`), the
# out-of-group branch. The tab bar is not the sidebar truncated: the mockup
# gives it its own shorter set, always ending in "Więcej", which opens a sheet
# holding whatever did not fit.
class Shared::Redesign::TabBarComponent < ViewComponent::Base
  attr_reader :user, :current_path, :group_chrome

  def initialize(user:, current_path:, group_chrome: nil)
    @user = user
    @current_path = current_path
    @group_chrome = group_chrome
  end

  private

  # In a group the tabs are that group's sections, not the top-level
  # destinations (10-core.js:193-195).
  def items
    @items ||= group_chrome ? group_chrome.tab_items : Redesign::Navigation.new(user).tab_items
  end
end
