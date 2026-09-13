# frozen_string_literal: true

# Redesign desktop sidebar.
#
# Ported from design/mockup-src/js-expanded/10-core.js:168 (`sidebar()`), the
# out-of-group branch: the primary nav, then a flat list of the user's groups,
# then the collapse toggle. The in-group `.deck` card and its section nav land
# with the first group screen.
class Shared::Redesign::SidebarComponent < ViewComponent::Base
  attr_reader :user, :current_path, :collapsed

  def initialize(user:, current_path:, collapsed: false)
    @user = user
    @current_path = current_path
    @collapsed = collapsed
  end

  private

  def nav_items
    @nav_items ||= Redesign::Navigation.new(user).primary_items
  end

  # `all_story_groups` already unions owned, taught and joined groups and
  # uniques them, which is exactly the mockup's "Twoje grupy" list.
  def groups
    @groups ||= user.all_story_groups.sort_by { |group| group.name.to_s.downcase }
  end

  # "Prowadzisz" for a group you own, "Wspierasz" for one you co-teach,
  # "Uczysz się" for one you joined as a student. Owner is checked first:
  # owning implies teaching. The labels come from StoryGroupsListing so this
  # list and the "Grupy" screen cannot disagree about what you are in a group.
  def role_label(story_group)
    StoryGroupsListing::ROLE_LABELS[role_for(story_group)]
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
    collapsed ? 'Rozwiń' : 'Zwiń panel'
  end

  def toggle_icon
    collapsed ? 'fa-angles-right' : 'fa-angles-left'
  end
end
