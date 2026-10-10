# frozen_string_literal: true

class Shared::TabBarComponent < ViewComponent::Base
  attr_reader :user, :current_path, :group_chrome

  def initialize(user:, current_path:, group_chrome: nil)
    @user = user
    @current_path = current_path
    @group_chrome = group_chrome
  end

  private

  def items
    @items ||= group_chrome ? group_chrome.tab_items : Navigation.new(user).tab_items
  end
end
