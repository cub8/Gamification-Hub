# frozen_string_literal: true

require 'test_helper'

# The in-group navigation chrome: the deck that replaces the group list, its
# section nav, the mobile switcher and tab bar (mockup `chrome: 'group'`,
# js-expanded/10-core.js:153).
class GroupChromeSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @owner = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Zakon Algorytmów')
    @other_group = FactoryBot.create(:story_group, owner: @owner, name: 'Kosmiczne króliki')
    @invite = FactoryBot.create(:story_group_invite, story_group: @story_group)
    sign_in @owner
  end

  # sign_in is a no-op while a session is live — the magic-link verify refuses
  # to run for someone already logged in — so switching user needs the sign_out.
  def sign_in_as(user)
    sign_out
    sign_in user
  end

  def deck_items
    css_select('.gh-deck .gh-nl').map { |link| link.text.strip }
  end

  # Zaproszenia is the only group screen on the redesign layout so far, so it
  # is the only place the chrome can actually be seen end to end.
  def visit_group_screen
    get story_group_invites_path(@story_group)
  end

  # --- the deck replaces the group list ------------------------------------

  test 'a group screen shows the deck instead of the list of your groups' do
    visit_group_screen

    assert_response :success
    assert_select '.gh-deck-name', 'Zakon Algorytmów'
    assert_select '.gh-deck-role', 'Prowadzisz tę grupę'
    # Mockup-faithful: the two never appear together (10-core.js:171-183).
    assert_select '.gh-glist', false
    assert_select '.gh-sb-sec', false
  end

  test 'out-of-group screens keep the group list and grow no deck' do
    get home_path

    assert_select '.gh-deck', false
    assert_select '.gh-glist a.gh-gl', 2
    # The count start_redesign_smoke_test pins: the section nav must not leak
    # out of a group.
    assert_select 'aside.gh-sb a.gh-nl', 2
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

    assert_select '.gh-deck-role', 'Wspierasz tę grupę'
    assert_includes deck_items, 'Studenci'
  end

  # --- which item is lit ----------------------------------------------------

  test 'a section stays lit on its own child pages' do
    visit_group_screen
    assert_select '.gh-deck .gh-nl--on', 'Zaproszenia'

    # The prefix rule: a dialog URL under /invites is still "Zaproszenia".
    get confirm_destroy_story_group_invite_path(@story_group, @invite)
    assert_select '.gh-deck .gh-nl--on', 'Zaproszenia'

    get edit_story_group_invite_path(@story_group, @invite)
    assert_select '.gh-deck .gh-nl--on', 'Zaproszenia'
  end

  # Przegląd is story_group_path, which is a prefix of every other group path.
  # Matching it by prefix would light it on every screen in the group.
  test 'Przeglad is never lit on a section screen' do
    visit_group_screen

    assert_select '.gh-deck .gh-nl--on', 1
    assert_select '.gh-deck .gh-nl--on', { text: 'Przegląd', count: 0 }
  end

  # --- the student variant --------------------------------------------------
  #
  # No student-visible group screen is on the redesign layout yet — invites
  # requires `update?` — so the student nav is exercised through the object
  # that builds it rather than through a request.

  test 'the student deck lists the sections a student actually has' do
    @story_group.update!(ranking_enabled: true)
    student = FactoryBot.create(:user, role: :student)
    membership = FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    chrome = Redesign::GroupChrome.for(user: student, story_group: @story_group)

    assert_predicate chrome, :student?
    assert_equal 'Jesteś uczestnikiem', chrome.role_label
    # Ranking after Historia waluty, as NAV_S has it (10-core.js:142-146) —
    # the teacher list puts it straight after Odznaki instead.
    assert_equal ['Przegląd',
                  'Sklep',
                  'Moje przedmioty',
                  'Rangi',
                  'Odznaki',
                  'Historia waluty',
                  'Ranking',
                  'Ustawienia w grupie',],
                 chrome.items.map(&:label)

    # The three student destinations that hang off the membership, not the group.
    assert_equal story_group_student_students_items_path(@story_group, membership),
                 chrome.items.find { |item| item.label == 'Moje przedmioty' }
                             .path
    assert_equal story_group_student_currency_transactions_path(@story_group, membership),
                 chrome.items.find { |item| item.label == 'Historia waluty' }
                             .path
  end

  test 'a student who owns a group as well still gets the student nav there' do
    # Membership decides the persona, not User#role: the dashboard beside the
    # nav branches the same way.
    teacher = FactoryBot.create(:user, role: :teacher)
    FactoryBot.create(:story_group_student, story_group: @story_group, user: teacher)
    chrome = Redesign::GroupChrome.for(user: teacher, story_group: @story_group)

    assert_predicate chrome, :student?
    assert_not_includes chrome.items.map(&:label), 'Zaproszenia'
  end

  # The entry stays put for everyone who may open the screen, and a student
  # always may: behind it with the ranking off is the panel saying so, which is
  # a screen and not a dead end. What the switch decides is what is ON that
  # screen, not whether the navigation admits it exists.
  test 'ranking follows the policy that guards the ranking screen' do
    student = FactoryBot.create(:user, role: :student)
    FactoryBot.create(:story_group_student, story_group: @story_group, user: student)

    @story_group.update!(ranking_enabled: false)
    assert_includes Redesign::GroupChrome.for(user: student, story_group: @story_group)
                                         .items.map(&:label), 'Ranking'
    # The teacher sees it either way — it is their switch to flip.
    assert_includes deck_labels_for(@owner), 'Ranking'

    @story_group.update!(ranking_enabled: true)
    assert_includes Redesign::GroupChrome.for(user: student, story_group: @story_group)
                                         .items.map(&:label), 'Ranking'
  end

  # --- who gets chrome at all ----------------------------------------------

  test 'a non-member gets no chrome even when a group is in scope' do
    outsider = FactoryBot.create(:user, role: :teacher)

    assert_nil Redesign::GroupChrome.for(user: outsider, story_group: @story_group)
  end

  # JoinController sets @story_group from an invite lookup for somebody who is
  # not in the group yet. The deck must not appear there.
  test 'the join screens show no deck for the group being joined' do
    joiner = FactoryBot.create(:user, role: :student)
    sign_in_as joiner

    get lookup_join_index_path(code: @invite.code), headers: { 'Turbo-Frame' => 'modal' }

    assert_response :success
    assert_select '.gh-deck', false
  end

  # A long group list has to scroll inside the panel rather than run off the
  # screen, and the footer has to stay reachable while it does — hence the
  # sticky .gh-pop-f rather than a plain spaced one.
  test 'the switcher keeps its footer reachable however many groups there are' do
    11.times { |index| FactoryBot.create(:story_group, owner: @owner, name: "Grupa #{index}") }

    visit_group_screen

    assert_select '#gh-group-switcher ul.gh-menu li a', 13
    # Inside the scrolling body, or `position: sticky` has nothing to stick to.
    assert_select '#gh-group-switcher .gh-dialog-body > .gh-pop-f a', 'Dołącz do grupy'
  end

  # --- mobile ---------------------------------------------------------------

  test 'the tab bar swaps to the group sections, with the shortened label' do
    visit_group_screen

    assert_equal(%w[Przegląd Studenci Arkusze Więcej],
                 css_select('.gh-tabbar .gh-tab').map { |tab| tab.text.strip },)
  end

  test 'the Wiecej sheet is a complete index of the group sections' do
    visit_group_screen

    assert_equal(deck_items, css_select('#gh-more-sheet .gh-more-m a').map { |a| a.text.strip })
    assert_select '#gh-more-sheet .gh-more-m a[aria-current]', 'Zaproszenia'
  end

  test 'the group switcher lists your groups and says which one you are in' do
    visit_group_screen

    # Inside .gh-shell, or menu#open cannot reach it — the same requirement the
    # account menu and the "Więcej" sheet already have.
    assert_select '.gh-shell #gh-group-switcher', 1
    assert_select '#gh-group-switcher ul.gh-menu li a', 2
    assert_select '#gh-group-switcher a[aria-current=page] .gh-cur', 'Tu jesteś'

    # Two ways in: the deck on desktop, the header switcher on a phone.
    assert_select '.gh-deck [data-menu-id-param=gh-group-switcher]', 1
    assert_select '.gh-hd .gh-gsw[data-menu-id-param=gh-group-switcher]', 1
  end

  test 'the header switcher names the group it would change' do
    visit_group_screen

    assert_select '.gh-gsw[aria-label=?]', 'Grupa Zakon Algorytmów, zmień grupę'
    assert_select '.gh-gsw .gh-gsw-name', 'Zakon Algorytmów'
  end

  private

  def deck_labels_for(user)
    Redesign::GroupChrome.for(user: user, story_group: @story_group).items.map(&:label)
  end
end
