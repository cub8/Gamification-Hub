# frozen_string_literal: true

class Shared::MainSidebarComponent < ViewComponent::Base
  attr_reader :current_path, :user, :story_group, :collapsed

  def initialize(current_path:, user:, story_group: nil, collapsed: false)
    @current_path = current_path
    @user = user
    @story_group = story_group
    @collapsed = collapsed
  end

  private

  def story_group_student?
    story_group.students.include?(user)
  end

  def sidebar_class
    collapsed ? 'sidebar-collapsed-desktop' : 'sidebar-full-desktop'
  end

  def toggle_button
    toggle_btn_icon = collapsed ? 'fa-angle-right' : 'fa-angle-left'
    toggle_btn_text = collapsed ? 'Pokaż' : 'Ukryj'

    Shared::SidebarButtonComponent.new(
      toggle_btn_text,
      nil,
      icon:         toggle_btn_icon,
      current_path: current_path,
      collapsed:    collapsed,
      data:         {
        action: 'desktop-sidebar#toggle',
      },
    )
  end

  def primary_buttons
    [
      { text: 'Strona główna', path: helpers.home_path, icon: 'fa-house' },
      { text: 'Grupy Fabularne', path: helpers.story_groups_path, icon: 'fa-book' },
    ]
  end

  def story_group_buttons
    return [] unless story_group

    if story_group_student?
      [
        { text: 'Sklep', path: helpers.story_group_items_path(story_group), icon: 'fa-sack-dollar' },
        { text: 'Ranking', path: helpers.story_group_ranking_path(story_group), icon: 'fa-ranking-star' },
        { text: 'Moje przedmioty', path: helpers.story_group_items_path(story_group), icon: 'fa-flask' },
        { text: 'Rangi', path: helpers.story_group_ranks_path(story_group), icon: 'fa-angles-up' },
        { text: 'Odznaki', path: helpers.story_group_badges_path(story_group), icon: 'fa-award' },
        { text: 'Nauczyciele', path: helpers.story_group_teachers_path(story_group), icon: 'fa-briefcase' },
      ]
    else
      [
        { text: 'Studenci', path: helpers.story_group_students_path(story_group), icon: 'fa-graduation-cap' },
        { text: 'Grupy aktywności', path: helpers.story_group_activity_groups_path(story_group), icon: 'fa-table' },
        { text: 'Przedmioty', path: helpers.story_group_items_path(story_group), icon: 'fa-flask' },
        { text: 'Rangi', path: helpers.story_group_ranks_path(story_group), icon: 'fa-angles-up' },
        { text: 'Odznaki', path: helpers.story_group_badges_path(story_group), icon: 'fa-award' },
        { text: 'Ranking', path: helpers.story_group_ranking_path(story_group), icon: 'fa-ranking-star' },
        { text: 'Zaproszenia', path: helpers.story_group_invites_path(story_group), icon: 'fa-qrcode' },
        { text: 'Nauczyciele', path: helpers.story_group_teachers_path(story_group), icon: 'fa-briefcase' },
        { text: 'Ustawienia grupy', path: helpers.edit_story_group_path(story_group), icon: 'fa-gears' },
      ]
    end
  end
end
