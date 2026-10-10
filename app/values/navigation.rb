# frozen_string_literal: true

class Navigation
  include Rails.application.routes.url_helpers

  Item = Data.define(:label, :path, :icon, :short, :match, :frame) do
    def initialize(label:, path:, icon:, short: nil, match: nil, frame: nil)
      super
    end

    def tab_label = short || label

    def current?(current_path)
      return current_path == path if match.nil?

      current_path == path || current_path.start_with?("#{match}/")
    end
  end

  TEACHER_TABS = ['Przegląd', 'Studenci', 'Arkusze ocen'].freeze
  STUDENT_TABS = ['Przegląd', 'Sklep', 'Moje przedmioty', 'Ranking'].freeze

  def initialize(user)
    @user = user
  end

  def primary_items
    [
      Item.new(label: 'Start',  path: home_path,         icon: 'fa-house'),
      (Item.new(label: 'Grupy', path: story_groups_path, icon: 'fa-book') unless @user.global_admin?),
      organization_item,
    ].compact
  end

  def tab_items
    items = primary_items
    if @user.teacher?
      items += [Item.new(label: 'Powiadomienia', path: notifications_path,
                         icon: 'fa-bell', frame: 'panel',)]
    end

    items
  end

  def group_items(chrome)
    items = chrome.student? ? student_items(chrome) : teacher_items(chrome)

    items.compact
  end

  def group_tab_items(chrome)
    wanted = chrome.student? ? STUDENT_TABS : TEACHER_TABS
    by_label = group_items(chrome).index_by(&:label)

    wanted.filter_map { |label| by_label[label] }
  end

  private

  def teacher_items(chrome)
    group = chrome.story_group

    [
      overview(group),
      section('Studenci',     story_group_students_path(group),         'fa-graduation-cap'),
      section('Arkusze ocen', story_group_activity_groups_path(group),  'fa-table', short: 'Arkusze'),
      section('Przedmioty',   story_group_items_path(group),            'fa-flask'),
      *shared_items(group),
      ranking_item(chrome),
      section('Zaproszenia',  story_group_invites_path(group),          'fa-qrcode'),
      section('Nauczyciele',  story_group_teachers_path(group),         'fa-briefcase'),
      section('Ustawienia grupy', edit_story_group_path(group),         'fa-gear'),
    ]
  end

  def student_items(chrome)
    group = chrome.story_group
    membership = chrome.student_membership

    [
      overview(group),
      section('Sklep', story_group_shop_index_path(group), 'fa-sack-dollar'),
      section('Moje przedmioty',
              story_group_student_students_items_path(group, membership),
              'fa-flask', short: 'Przedmioty',),
      *shared_items(group),
      section('Historia waluty',
              story_group_student_currency_transactions_path(group, membership),
              'fa-clock-rotate-left',),
      ranking_item(chrome),
      section('Ustawienia w grupie', edit_story_group_membership_path(group), 'fa-gear'),
    ]
  end

  def shared_items(group)
    [
      section('Rangi',   story_group_ranks_path(group),  'fa-angles-up'),
      section('Odznaki', story_group_badges_path(group), 'fa-award'),
    ]
  end

  def ranking_item(chrome)
    return unless chrome.ranking?

    section('Ranking', story_group_ranking_path(chrome.story_group), 'fa-ranking-star')
  end

  # Global admins manage every organization; an organization admin goes
  # straight to their own.
  def organization_item
    if @user.global_admin?
      Item.new(label: 'Organizacje', path: organizations_path, icon: 'fa-briefcase', match: organizations_path)
    elsif @user.organization_admin? && @user.organization
      path = organization_path(@user.organization)
      Item.new(label: @user.organization.name, path: path, icon: 'fa-briefcase',
               short: 'Organizacja', match: path,)
    end
  end

  def overview(group)
    Item.new(label: 'Przegląd', path: story_group_path(group), icon: 'fa-table-columns')
  end

  def section(label, path, icon, short: nil)
    Item.new(label: label, path: path, icon: icon, short: short, match: path)
  end
end
