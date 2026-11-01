# frozen_string_literal: true

# Items carry a key so the tab bar can pick them without matching on wording.
class Navigation
  include Rails.application.routes.url_helpers

  Item = Data.define(:key, :label, :path, :icon, :short, :match, :frame) do
    def initialize(key:, label:, path:, icon:, short: nil, match: nil, frame: nil)
      super
    end

    def tab_label = short || label

    def current?(current_path)
      return current_path == path if match.nil?

      current_path == path || current_path.start_with?("#{match}/")
    end
  end

  TEACHER_TABS = %i[overview students sheets].freeze
  STUDENT_TABS = %i[overview shop my_items ranking].freeze

  def initialize(user)
    @user = user
  end

  def primary_items
    [
      item(:start,  home_path,         'fa-house'),
      (item(:groups, story_groups_path, 'fa-book') unless @user.global_admin?),
      organization_item,
    ].compact
  end

  def tab_items
    items = primary_items
    items += [item(:notifications, notifications_path, 'fa-bell', frame: 'panel')] if @user.teacher?

    items
  end

  def group_items(chrome)
    items = chrome.student? ? student_items(chrome) : teacher_items(chrome)

    items.compact
  end

  def group_tab_items(chrome)
    wanted = chrome.student? ? STUDENT_TABS : TEACHER_TABS
    by_key = group_items(chrome).index_by(&:key)

    wanted.filter_map { |key| by_key[key] }
  end

  private

  def teacher_items(chrome)
    group = chrome.story_group

    [
      overview(group),
      section(:students, story_group_students_path(group),        'fa-graduation-cap'),
      section(:sheets,   story_group_activity_groups_path(group), 'fa-table', short: true),
      section(:items,    story_group_items_path(group),           'fa-flask'),
      *shared_items(group),
      ranking_item(chrome),
      section(:invites,  story_group_invites_path(group),         'fa-qrcode'),
      section(:teachers, story_group_teachers_path(group),        'fa-briefcase'),
      section(:export,   story_group_export_path(group),          'fa-file-export'),
      section(:settings, edit_story_group_path(group),            'fa-gear'),
    ]
  end

  def student_items(chrome)
    group = chrome.story_group
    membership = chrome.student_membership

    [
      overview(group),
      section(:shop, story_group_shop_index_path(group), 'fa-sack-dollar'),
      section(:my_items,
              story_group_student_students_items_path(group, membership),
              'fa-flask', short: true,),
      *shared_items(group),
      section(:history,
              story_group_student_currency_transactions_path(group, membership),
              'fa-clock-rotate-left',),
      ranking_item(chrome),
      section(:membership, edit_story_group_membership_path(group), 'fa-gear'),
    ]
  end

  def shared_items(group)
    [
      section(:ranks,  story_group_ranks_path(group),  'fa-angles-up'),
      section(:badges, story_group_badges_path(group), 'fa-award'),
    ]
  end

  def ranking_item(chrome)
    return unless chrome.ranking?

    section(:ranking, story_group_ranking_path(chrome.story_group), 'fa-ranking-star')
  end

  def organization_item
    if @user.global_admin?
      section(:organizations, organizations_path, 'fa-briefcase')
    elsif @user.organization_admin? && @user.organization
      path = organization_path(@user.organization)
      Item.new(key: :organization, label: @user.organization.name, path: path, icon: 'fa-briefcase',
               short: label('short.organization'), match: path,)
    end
  end

  def overview(group)
    item(:overview, story_group_path(group), 'fa-table-columns')
  end

  def item(key, path, icon, frame: nil)
    Item.new(key: key, label: label(key), path: path, icon: icon, frame: frame)
  end

  def section(key, path, icon, short: false)
    Item.new(key: key, label: label(key), path: path, icon: icon, match: path,
             short: (label("short.#{key}") if short),)
  end

  def label(key) = I18n.t("layouts.navigation.#{key}")
end
