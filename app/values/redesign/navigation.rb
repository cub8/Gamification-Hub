# frozen_string_literal: true

module Redesign
  # The redesign's top-level navigation, in one place.
  #
  # The sidebar, the mobile tab bar and the "Więcej" sheet all render the same
  # destinations; the mockup derives all three from one `NAV_G` list
  # (js-expanded/10-core.js:131) and so do we. A read-only value object: it
  # builds paths and labels and touches no database.
  #
  # Only the OUT-OF-GROUP navigation lives here. The in-group section nav
  # (`NAV_S` / `NAV_T`) arrives with the first group screen, at which point it
  # becomes a second method here rather than a second list somewhere else.
  class Navigation
    include Rails.application.routes.url_helpers

    Item = Struct.new(:label, :path, :icon)

    def initialize(user)
      @user = user
    end

    # Icons deliberately match Shared::MainSidebarComponent#primary_buttons —
    # the Bootstrap sidebar is already Font Awesome, and the two navigations
    # coexist until the last controller is converted.
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
      items += [Item.new(label: 'Powiadomienia', path: notifications_path, icon: 'fa-bell')] if @user.teacher?
      items
    end
  end
end
