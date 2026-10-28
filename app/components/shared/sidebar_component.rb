# frozen_string_literal: true

class Shared::SidebarComponent < ViewComponent::Base
  attr_reader :user, :current_path, :collapsed, :group_chrome

  def initialize(user:, current_path:, collapsed: false, group_chrome: nil)
    @user = user
    @current_path = current_path
    @collapsed = collapsed
    @group_chrome = group_chrome
  end

  private

  def nav_items
    @nav_items ||= Navigation.new(user).primary_items
  end

  def groups
    @groups ||= if user.global_admin?
                  []
                else
                  user.all_story_groups.sort_by { |group| group.name.to_s.downcase }
                end
  end

  def role_label(story_group)
    t("story_groups.listing.roles.#{role_for(story_group)}")
  end

  def role_for(story_group)
    return :own if story_group.owner_id == user.id
    return :sup if teacher_group_ids.include?(story_group.id)

    :lrn
  end

  def teacher_group_ids
    @teacher_group_ids ||= user.teacher_story_groups.ids
  end

  def current?(path)
    current_path == path
  end

  def toggle_label
    collapsed ? t('layouts.sidebar.expand') : t('layouts.sidebar.collapse')
  end

  def toggle_icon
    collapsed ? 'fa-angles-right' : 'fa-angles-left'
  end
end
