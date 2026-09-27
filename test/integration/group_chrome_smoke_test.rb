# frozen_string_literal: true

require 'test_helper'

class GroupChromeSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @owner = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Zakon Algorytmów')
    @other_group = FactoryBot.create(:story_group, owner: @owner, name: 'Kosmiczne króliki')
    @invite = FactoryBot.create(:story_group_invite, story_group: @story_group)
    sign_in @owner
  end

  def sign_in_as(user)
    sign_out
    sign_in user
  end

  def deck_items
    css_select('.gh-current-group-card .gh-sidebar-link').map { |link| link.text.strip }
  end

  def visit_group_screen
    get story_group_invites_path(@story_group)
  end

  test 'a group screen shows the deck instead of the list of your groups' do
    visit_group_screen

    assert_response :success
    assert_select '.gh-current-group-card-name', 'Zakon Algorytmów'
    assert_select '.gh-current-group-card-role', 'Prowadzisz tę grupę'
    assert_select '.gh-sidebar-group-list', false
    assert_select '.gh-sidebar-section-label', false
  end

  test 'out-of-group screens keep the group list and grow no deck' do
    get home_path

    assert_select '.gh-current-group-card', false
    assert_select '.gh-sidebar-group-list a.gh-sidebar-group-list-item', 2
    assert_select 'aside.gh-sidebar a.gh-sidebar-link', 2
  end

  test 'the teacher deck lists every section of the group' do
    visit_group_screen

    assert_equal ['Przegląd',
                  'Studenci',
                  'Arkusze ocen',
                  'Przedmioty',
                  'Rangi',
                  'Odznaki',
                  'Ranking',
                  'Zaproszenia',
                  'Nauczyciele',
                  'Ustawienia grupy',],
                 deck_items
  end

  test 'a supporting teacher gets the teacher nav and is told they support it' do
    supporter = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_teacher, story_group: @story_group, user: supporter)
    sign_in_as supporter

    visit_group_screen

    assert_select '.gh-current-group-card-role', 'Wspierasz tę grupę'
    assert_includes deck_items, 'Studenci'
  end

  test 'a section stays lit on its own child pages' do
    visit_group_screen
    assert_select '.gh-current-group-card .gh-sidebar-link--active', 'Zaproszenia'

    get confirm_destroy_story_group_invite_path(@story_group, @invite)
    assert_select '.gh-current-group-card .gh-sidebar-link--active', 'Zaproszenia'

    get edit_story_group_invite_path(@story_group, @invite)
    assert_select '.gh-current-group-card .gh-sidebar-link--active', 'Zaproszenia'
  end

  test 'Przeglad is never lit on a section screen' do
    visit_group_screen

    assert_select '.gh-current-group-card .gh-sidebar-link--active', 1
    assert_select '.gh-current-group-card .gh-sidebar-link--active', { text: 'Przegląd', count: 0 }
  end

  test 'the student deck lists the sections a student actually has' do
    @story_group.update!(ranking_enabled: true)
    student = FactoryBot.create(:user, role: :student)
    membership = FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    chrome = GroupChrome.for(user: student, story_group: @story_group)

    assert_predicate chrome, :student?
    assert_equal 'Jesteś uczestnikiem', chrome.role_label
    assert_equal ['Przegląd',
                  'Sklep',
                  'Moje przedmioty',
                  'Rangi',
                  'Odznaki',
                  'Historia waluty',
                  'Ranking',
                  'Ustawienia w grupie',],
                 chrome.items.map(&:label)

    assert_equal story_group_student_students_items_path(@story_group, membership),
                 chrome.items.find { |item| item.label == 'Moje przedmioty' }
                             .path
    assert_equal story_group_student_currency_transactions_path(@story_group, membership),
                 chrome.items.find { |item| item.label == 'Historia waluty' }
                             .path
  end

  test 'a student who owns a group as well still gets the student nav there' do
    teacher = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_student, story_group: @story_group, user: teacher)
    chrome = GroupChrome.for(user: teacher, story_group: @story_group)

    assert_predicate chrome, :student?
    assert_not_includes chrome.items.map(&:label), 'Zaproszenia'
  end

  test 'ranking follows the policy that guards the ranking screen' do
    student = FactoryBot.create(:user, role: :student)
    FactoryBot.create(:story_group_student, story_group: @story_group, user: student)

    @story_group.update!(ranking_enabled: false)
    assert_includes GroupChrome.for(user: student, story_group: @story_group)
                               .items.map(&:label), 'Ranking'
    assert_includes deck_labels_for(@owner), 'Ranking'

    @story_group.update!(ranking_enabled: true)
    assert_includes GroupChrome.for(user: student, story_group: @story_group)
                               .items.map(&:label), 'Ranking'
  end

  test 'a non-member gets no chrome even when a group is in scope' do
    outsider = FactoryBot.create(:user, role: :teacher)

    assert_nil GroupChrome.for(user: outsider, story_group: @story_group)
  end

  test 'the join screens show no deck for the group being joined' do
    joiner = FactoryBot.create(:user, role: :student)
    sign_in_as joiner

    get lookup_join_index_path(code: @invite.code), headers: { 'Turbo-Frame' => 'modal' }

    assert_response :success
    assert_select '.gh-current-group-card', false
  end

  test 'the switcher keeps its footer reachable however many groups there are' do
    11.times { |index| FactoryBot.create(:story_group, owner: @owner, name: "Grupa #{index}") }

    visit_group_screen

    assert_select '#gh-group-switcher ul.gh-menu-list li a', 13
    assert_select '#gh-group-switcher .gh-dialog-body > .gh-popover-footer a', 'Dołącz do grupy'
  end

  test 'the tab bar swaps to the group sections, with the shortened label' do
    visit_group_screen

    assert_equal(%w[Przegląd Studenci Arkusze Więcej],
                 css_select('.gh-mobile-tabbar .gh-mobile-tab').map { |tab| tab.text.strip },)
  end

  test 'the Wiecej sheet is a complete index of the group sections' do
    visit_group_screen

    assert_equal(deck_items, css_select('#gh-more-sheet .gh-menu-list--nav a').map { |a| a.text.strip })
    assert_select '#gh-more-sheet .gh-menu-list--nav a[aria-current]', 'Zaproszenia'
  end

  test 'the group switcher lists your groups and says which one you are in' do
    visit_group_screen

    assert_select '.gh-app-shell #gh-group-switcher', 1
    assert_select '#gh-group-switcher ul.gh-menu-list li a', 2
    assert_select '#gh-group-switcher a[aria-current=page] .gh-current-badge', 'Tu jesteś'

    assert_select '.gh-current-group-card [data-menu-id-param=gh-group-switcher]', 1
    assert_select '.gh-topbar .gh-group-switcher[data-menu-id-param=gh-group-switcher]', 1
  end

  test 'the header switcher names the group it would change' do
    visit_group_screen

    assert_select '.gh-group-switcher[aria-label=?]', 'Grupa Zakon Algorytmów, zmień grupę'
    assert_select '.gh-group-switcher .gh-group-switcher-name', 'Zakon Algorytmów'
  end

  private

  def deck_labels_for(user)
    GroupChrome.for(user: user, story_group: @story_group).items.map(&:label)
  end
end
