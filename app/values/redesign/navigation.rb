# frozen_string_literal: true

module Redesign
  # The redesign's navigation, in one place.
  #
  # The sidebar, the mobile tab bar and the "Więcej" sheet all render the same
  # destinations; the mockup derives each set from one list
  # (js-expanded/10-core.js:131-147) and so do we. A read-only value object: it
  # builds paths and labels and touches no database — the membership and the
  # role it needs for the in-group lists arrive already resolved, in a
  # Redesign::GroupChrome.
  class Navigation
    include Rails.application.routes.url_helpers

    # `short`  — the tab bar shortens two labels (10-core.js:194-195).
    # `match`  — path prefix for "still current on a child page", the mockup's
    #            `sec:`. nil means exact match only.
    # `frame`  — turbo frame this destination opens into, if any.
    Item = Data.define(:label, :path, :icon, :short, :match, :frame) do
      def initialize(label:, path:, icon:, short: nil, match: nil, frame: nil)
        super
      end

      def tab_label = short || label

      # Exact for an item with no `match`, prefix otherwise. Przegląd is the
      # reason the distinction exists: story_group_path is a prefix of every
      # other group path, so a prefix rule there would light it everywhere.
      def current?(current_path)
        return current_path == path if match.nil?

        current_path == path || current_path.start_with?("#{match}/")
      end
    end

    # Which sections get a tab. "Więcej" is not here — the tab bar renders it
    # itself (10-core.js:194-195).
    TEACHER_TABS = ['Przegląd', 'Studenci', 'Arkusze ocen'].freeze
    STUDENT_TABS = ['Przegląd', 'Sklep', 'Moje przedmioty', 'Ranking'].freeze

    def initialize(user)
      @user = user
    end

    # Icons deliberately match Shared::MainSidebarComponent — the Bootstrap
    # sidebar is already Font Awesome, and the two navigations coexist until
    # the last controller is converted.
    def primary_items
      [
        Item.new(label: 'Start',  path: home_path,         icon: 'fa-house'),
        Item.new(label: 'Grupy',  path: story_groups_path, icon: 'fa-book'),
      ]
    end

    # The tab bar is not the sidebar truncated: the mockup gives it its own
    # shorter set, with "Więcej" always last and notifications promoted to a
    # tab for teachers (10-core.js:190).
    def tab_items
      items = primary_items
      if @user.teacher?
        items += [Item.new(label: 'Powiadomienia', path: notifications_path,
                           icon: 'fa-bell', frame: 'panel',)]
      end

      items
    end

    # NAV_T / NAV_S (10-core.js:135-147), against the routes that exist today.
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

    # Seven, not the mockup's eight: "Ustawienia w grupie" has no screen, and
    # students_profile#index is "Mój profil", not settings. Pointing the label
    # at it would be a lie, so it waits for the screen DECISIONS.md promises.
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
      ]
    end

    # Rangi and Odznaki are the same screens for everyone — ranks#index and
    # badges#index authorize with `show?`, so a member sees the group's list.
    def shared_items(group)
      [
        section('Rangi',   story_group_ranks_path(group),  'fa-angles-up'),
        section('Odznaki', story_group_badges_path(group), 'fa-award'),
      ]
    end

    # Placed by hand in each list rather than shared: the mockup puts Ranking
    # straight after Odznaki for a teacher but after Historia waluty for a
    # student (10-core.js:138-146). Nil when the policy hides the screen.
    def ranking_item(chrome)
      return unless chrome.ranking?

      section('Ranking', story_group_ranking_path(chrome.story_group), 'fa-ranking-star')
    end

    # No `match`: every other group path starts with this one.
    def overview(group)
      Item.new(label: 'Przegląd', path: story_group_path(group), icon: 'fa-table-columns')
    end

    # `match` defaults to the item's own path, so a detail or form page under it
    # keeps the section lit — /invites/5/confirm_destroy lights "Zaproszenia".
    def section(label, path, icon, short: nil)
      Item.new(label: label, path: path, icon: icon, short: short, match: path)
    end
  end
end
