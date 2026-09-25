# frozen_string_literal: true

require 'test_helper'

# "Ranking" — RankingController.
# One action, two screens: the teacher's full board (mockup #/t/ranking) and the
# student's own view of it (#/s/ranking), plus the four dialogs that change what
# students see.
class RankingSmokeTest < ActionDispatch::IntegrationTest
  def group(**attrs)
    FactoryBot.create(:story_group,
                      { name: 'Kosmiczne króliki', currency_name: 'Marchewek' }.merge(attrs),)
  end

  def student_in(story_group, name:, total: 0, nickname: nil)
    FactoryBot.create(:story_group_student,
                      story_group:      story_group,
                      user:             FactoryBot.create(:user, role: :student, full_name: name),
                      nickname:         nickname,
                      lives:            3,
                      current_currency: total,
                      total_currency:   total,)
  end

  def teacher_of(story_group)
    story_group.owner
  end

  def places
    css_select('.gh-ranking-row .gh-position-badge').map { |node| node.text.strip }
  end

  # --- layout ---------------------------------------------------------------

  test 'the ranking renders inside the app chrome for a teacher' do
    story_group = group(ranking_enabled: true)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_response :success
    assert_select '.gh-app-shell header.gh-topbar'
    assert_no_match(/data-bs-/, response.body)
  end

  test 'the ranking renders inside the app chrome for a student' do
    story_group = group(ranking_enabled: true)
    membership = student_in(story_group, name: 'Sebastian Alejandro')

    sign_in membership.user
    get story_group_ranking_path(story_group)

    assert_response :success
    assert_select '.gh-app-shell header.gh-topbar'
  end

  # --- the two perspectives -------------------------------------------------

  test 'the teacher sees the nickname over the real name' do
    story_group = group(ranking_enabled: true)
    student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Rakietowy Seba', total: 40)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_select '.gh-ranking-row .gh-ranking-name b', /Rakietowy Seba/
    assert_select '.gh-ranking-row .gh-ranking-name small', 'Sebastian Alejandro'
    assert_select '.gh-ranking-row--header span', 'Pseudonim i student'
  end

  # Ours diverges from the mockup, whose nickname is mandatory: a blank one
  # already falls back to the real name, so the marker replaces the second line
  # rather than the first.
  test 'the teacher sees a marker instead of a second line for a student with no nickname' do
    story_group = group(ranking_enabled: true)
    student_in(story_group, name: 'Adam Pawłowski', total: 10)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_select '.gh-ranking-row .gh-ranking-name b', /Adam Pawłowski/
    assert_select '.gh-ranking-row .gh-ranking-name small.gh-empty-note', 'Bez pseudonimu'
  end

  test 'a student sees nobody else\'s real name' do
    story_group = group(ranking_enabled: true, ranking_mode: :full)
    student_in(story_group, name: 'Barbara Kowalewska', nickname: 'Nova', total: 80)
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba', total: 40)

    sign_in membership.user
    get story_group_ranking_path(story_group)

    assert_response :success
    assert_select '.gh-ranking-row .gh-ranking-name b', /Nova/
    assert_no_match(/Barbara Kowalewska/, response.body)
    assert_select '.gh-ranking-row--header span', 'Pseudonim'
    # Their own row is marked, and nobody else's is.
    assert_select '.gh-ranking-row--me .gh-you-badge', 'Ty'
    assert_select '.gh-ranking-row--me', 1
  end

  # The ranking is the ONE screen where a nickname stands in for a person. The
  # grading sheet and the students list went the other way, so this guards the
  # two rules against drifting into each other.
  test 'the ranking still leads with the nickname, unlike every teacher list' do
    story_group = group(ranking_enabled: true)
    student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Rakietowy Seba', total: 40)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_select '.gh-ranking-row .gh-ranking-name b', /Rakietowy Seba/
    assert_select '.gh-ranking-row .gh-ranking-name small', 'Sebastian Alejandro'
  end

  # --- placement ------------------------------------------------------------

  test 'ties share a place and the next place skips' do
    story_group = group(ranking_enabled: true)
    student_in(story_group, name: 'Anna Nowak', nickname: 'Nova', total: 40)
    student_in(story_group, name: 'Barbara Kowalewska', nickname: 'Orbita', total: 40)
    student_in(story_group, name: 'Cezary Zając', nickname: 'Meteor', total: 10)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_equal %w[1 1 3], places
  end

  test 'the rank column names the highest rung at or below the total' do
    story_group = group(ranking_enabled: true)
    FactoryBot.create(:rank, story_group: story_group, name: 'Rekrut', required_currency_value: 0)
    FactoryBot.create(:rank, story_group: story_group, name: 'Pilot', required_currency_value: 40)
    student_in(story_group, name: 'Anna Nowak', nickname: 'Nova', total: 45)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_select '.gh-ranking-row .gh-ranking-rank-cell', 'Pilot'
  end

  # --- what the mode hides --------------------------------------------------

  test 'podium mode gives a student the top three, a gap and their own row' do
    story_group = group(ranking_enabled: true, ranking_mode: :podium_and_own)
    %w[Nova Orbita Meteor Kosmo].each_with_index do |nick, index|
      student_in(story_group, name: "Student #{index}", nickname: nick, total: 100 - (index * 10))
    end
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba', total: 5)

    sign_in membership.user
    get story_group_ranking_path(story_group)

    assert_equal %w[1 2 3 5], places
    assert_select '.gh-ranking-row--hidden-gap', 1
    assert_select '.gh-ranking-row--hidden-gap .gh-empty-note', 'Pozostałe miejsca są ukryte'
    assert_no_match(/Kosmo/, response.body)
  end

  test 'podium mode shows no gap row to a student already on the podium' do
    story_group = group(ranking_enabled: true, ranking_mode: :podium_and_own)
    student_in(story_group, name: 'Anna Nowak', nickname: 'Nova', total: 100)
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba', total: 50)
    student_in(story_group, name: 'Cezary Zając', nickname: 'Meteor', total: 10)

    sign_in membership.user
    get story_group_ranking_path(story_group)

    assert_equal %w[1 2 3], places
    assert_select '.gh-ranking-row--hidden-gap', false
  end

  test 'full mode shows a student every row' do
    story_group = group(ranking_enabled: true, ranking_mode: :full)
    4.times { |i| student_in(story_group, name: "Student #{i}", nickname: "Nick#{i}", total: 100 - (i * 10)) }
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba', total: 5)

    sign_in membership.user
    get story_group_ranking_path(story_group)

    assert_equal %w[1 2 3 4 5], places
    assert_select '.gh-ranking-row--hidden-gap', false
  end

  test 'the teacher always sees everyone, whatever students see' do
    story_group = group(ranking_enabled: false)
    4.times { |i| student_in(story_group, name: "Student #{i}", nickname: "Nick#{i}", total: 100 - (i * 10)) }

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_equal %w[1 2 3 4], places
  end

  # --- the hidden state -----------------------------------------------------

  test 'a student reaches the screen with the ranking off and gets the panel' do
    story_group = group(ranking_enabled: false)
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba', total: 40)

    sign_in membership.user
    get story_group_ranking_path(story_group)

    assert_response :success
    assert_select '.gh-empty-state h2', 'Ranking jest teraz ukryty'
    assert_select '.gh-ranking-row', false
    # Their own total and nickname stay theirs; the place does not exist.
    assert_select '.gh-my-ranking-stats b', '40'
    assert_no_match(/Twoje miejsce/, response.body)
  end

  test 'the sidebar keeps the ranking entry for a student with the ranking off' do
    story_group = group(ranking_enabled: false)
    membership = student_in(story_group, name: 'Sebastian Alejandro')

    sign_in membership.user
    get story_group_path(story_group)

    assert_select 'a[href=?]', story_group_ranking_path(story_group)
  end

  test 'the overview stops naming a place while the ranking is off' do
    story_group = group(ranking_enabled: false)
    membership = student_in(story_group, name: 'Sebastian Alejandro', total: 40)

    sign_in membership.user
    get story_group_path(story_group)

    assert_response :success
    assert_no_match(/miejsce w rankingu grupy/, response.body)
  end

  # --- the teacher's controls -----------------------------------------------

  test 'the switch points at the opposite of the current visibility' do
    story_group = group(ranking_enabled: false)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_select 'a.gh-toggle-switch[role=switch][aria-checked=false]' do
      assert_select '[href=?]', confirm_visibility_story_group_ranking_path(story_group, enabled: true)
    end
    # Nothing for the mode to describe while the board is off.
    assert_select '.gh-segmented-toggle-2', false
  end

  test 'the mode pair links only the mode not in force' do
    story_group = group(ranking_enabled: true, ranking_mode: :podium_and_own)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)

    assert_select '.gh-segmented-toggle-2 span[aria-pressed=true]', 'Podium i własne miejsce'
    assert_select '.gh-segmented-toggle-2 a[href=?]', confirm_mode_story_group_ranking_path(story_group, mode: 'full')
    assert_select '.gh-segmented-toggle-2 a[href=?]',
                  confirm_mode_story_group_ranking_path(story_group, mode: 'podium_and_own'), false
  end

  test 'the note explains only what students see less of' do
    story_group = group(ranking_enabled: true, ranking_mode: :podium_and_own)

    sign_in teacher_of(story_group)
    get story_group_ranking_path(story_group)
    assert_select '.gh-ranking-visibility-note b', 'Studenci widzą tylko podium i swoje miejsce.'

    story_group.ranking_full!
    get story_group_ranking_path(story_group)
    assert_select '.gh-ranking-visibility-note', false
  end

  # --- the dialogs ----------------------------------------------------------

  test 'enabling asks for the mode in the same dialog' do
    story_group = group(ranking_enabled: false)

    sign_in teacher_of(story_group)
    get confirm_visibility_story_group_ranking_path(story_group, enabled: true)

    assert_response :success
    assert_select 'h2', 'Pokazać ranking studentom?'
    assert_select '.gh-choice-grid[role=radiogroup] input[type=radio]', 2
    assert_select 'input[name=?][value=?]', 'story_group[ranking_enabled]', 'true'
  end

  test 'hiding is confirmed too' do
    story_group = group(ranking_enabled: true)

    sign_in teacher_of(story_group)
    get confirm_visibility_story_group_ranking_path(story_group, enabled: false)

    assert_response :success
    assert_select 'h2', 'Ukryć ranking przed studentami?'
    assert_select 'input[name=?][value=?]', 'story_group[ranking_enabled]', 'false'
  end

  test 'both mode changes are confirmed' do
    story_group = group(ranking_enabled: true, ranking_mode: :podium_and_own)

    sign_in teacher_of(story_group)

    get confirm_mode_story_group_ranking_path(story_group, mode: 'full')
    assert_select 'h2', 'Pokazać pełny ranking?'

    get confirm_mode_story_group_ranking_path(story_group, mode: 'podium_and_own')
    assert_select 'h2', 'Ograniczyć ranking do podium?'
  end

  test 'an unknown mode is not a screen' do
    story_group = group(ranking_enabled: true)

    sign_in teacher_of(story_group)
    get confirm_mode_story_group_ranking_path(story_group, mode: 'everything')

    assert_redirected_to root_path
  end

  test 'the dialogs render into the modal frame when asked for through it' do
    story_group = group(ranking_enabled: true)

    sign_in teacher_of(story_group)
    get confirm_visibility_story_group_ranking_path(story_group, enabled: false),
        headers: { 'Turbo-Frame' => 'modal' }

    assert_response :success
    assert_select 'turbo-frame#modal'
    assert_select '.gh-app-shell', false
  end

  # --- writing --------------------------------------------------------------

  test 'the teacher turns the ranking on with a mode' do
    story_group = group(ranking_enabled: false)

    sign_in teacher_of(story_group)
    patch story_group_ranking_path(story_group),
          params: { story_group: { ranking_enabled: true, ranking_mode: 'full' } }

    assert_response :success
    assert story_group.reload.ranking_enabled?
    assert story_group.ranking_full?
    assert_equal 'Ranking widoczny w całości.', flash[:notice]
  end

  test 'the teacher narrows the mode without touching visibility' do
    story_group = group(ranking_enabled: true, ranking_mode: :full)

    sign_in teacher_of(story_group)
    patch story_group_ranking_path(story_group),
          params: { story_group: { ranking_mode: 'podium_and_own' } }

    assert story_group.reload.ranking_enabled?
    assert story_group.ranking_podium_and_own?
    assert_equal 'Ranking widoczny: podium i własne miejsce.', flash[:notice]
  end

  test 'the teacher hides the ranking' do
    story_group = group(ranking_enabled: true)

    sign_in teacher_of(story_group)
    patch story_group_ranking_path(story_group), params: { story_group: { ranking_enabled: false } }

    assert_not story_group.reload.ranking_enabled?
    assert_equal 'Ranking ukryty przed studentami.', flash[:notice]
  end

  test 'a student cannot change what the ranking shows' do
    story_group = group(ranking_enabled: false)
    membership = student_in(story_group, name: 'Sebastian Alejandro')

    sign_in membership.user
    patch story_group_ranking_path(story_group), params: { story_group: { ranking_enabled: true } }

    assert_redirected_to root_path
    assert_not story_group.reload.ranking_enabled?
  end

  test 'a student cannot open the confirmation dialogs' do
    story_group = group(ranking_enabled: true)
    membership = student_in(story_group, name: 'Sebastian Alejandro')

    sign_in membership.user
    get confirm_visibility_story_group_ranking_path(story_group, enabled: false)

    assert_redirected_to root_path
  end

  # --- the nickname dialog --------------------------------------------------

  test 'the student ranking screen offers the nickname dialog' do
    story_group = group(ranking_enabled: true)
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba')

    sign_in membership.user
    get story_group_ranking_path(story_group)

    assert_select '.gh-nickname-row b', 'Seba'
    assert_select '.gh-nickname-row a[href=?]', nickname_story_group_membership_path(story_group)
  end

  test 'the nickname dialog saves and returns to the ranking' do
    story_group = group(ranking_enabled: true)
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba')

    sign_in membership.user
    get nickname_story_group_membership_path(story_group)
    assert_select 'h2', 'Pseudonim w grupie Kosmiczne króliki'

    patch story_group_membership_path(story_group),
          params: { return_to: 'ranking', story_group_student: { nickname: 'Rakietowy Seba' } }

    assert_response :success
    assert_equal 'Rakietowy Seba', membership.reload.nickname
    assert_match story_group_ranking_path(story_group), response.body
  end

  test 'a taken nickname comes back in the dialog, not the settings page' do
    story_group = group(ranking_enabled: true)
    student_in(story_group, name: 'Barbara Kowalewska', nickname: 'Nova')
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba')

    sign_in membership.user
    patch story_group_membership_path(story_group),
          params: { return_to: 'ranking', story_group_student: { nickname: 'nova' } }

    assert_response :unprocessable_content
    assert_select 'h2', 'Pseudonim w grupie Kosmiczne króliki'
    assert_select '.gh-field-error span', 'Ten pseudonim jest już zajęty w tej grupie.'
    assert_equal 'Seba', membership.reload.nickname
  end

  test 'the settings page still saves to itself' do
    story_group = group(ranking_enabled: true)
    membership = student_in(story_group, name: 'Sebastian Alejandro', nickname: 'Seba')

    sign_in membership.user
    patch story_group_membership_path(story_group),
          params: { story_group_student: { nickname: 'Nova' } }

    assert_redirected_to edit_story_group_membership_path(story_group)
    assert_equal 'Nova', membership.reload.nickname
  end
end
