# frozen_string_literal: true

require 'test_helper'

# The Nauczyciele screen: the list that shows the owner beside the supporting
# teachers, the search-first add dialog and the removal confirmation
# (mockup #/t/teachers, 30-rk.js `vTeachers` / `mAddT` / `mRmT`).
class TeachersRedesignSmokeTest < ActionDispatch::IntegrationTest
  MODAL = { 'Turbo-Frame' => 'modal' }.freeze

  setup do
    @owner = FactoryBot.create(:user, role: :teacher, full_name: 'Zofia Zawadzka')
    @story_group = FactoryBot.create(:story_group, owner: @owner, name: 'Zakon Algorytmów')
    sign_in @owner
  end

  def teacher(name, university: 'Example university')
    FactoryBot.create(:user, role: :teacher, full_name: name, university_name: university)
  end

  def supporting(name)
    FactoryBot.create(:story_group_teacher, user: teacher(name), story_group: @story_group)
  end

  # sign_in is a no-op while a session is live — the magic-link verify refuses
  # to run for someone already logged in — so switching user needs the sign_out.
  def sign_in_as(user)
    sign_out
    sign_in user
  end

  # --- the list -------------------------------------------------------------

  test 'the owner heads the list, explained and without a way to remove them' do
    supporting('Adam Adamczyk')

    get story_group_teachers_path(@story_group)

    assert_response :success
    rows = css_select('.gh-trow').reject { |row| row['class'].include?('gh-trow--h') }
    assert_equal(['Zofia Zawadzka', 'Adam Adamczyk'], rows.map { |row| row.css('.gh-tn b').text })
    assert_equal 'WłaścicielUtworzył grupę', rows.first.css('.gh-role').text.delete("\n").strip
    assert_equal 0, rows.first.css('a').size
  end

  test 'a supporting teacher is named as one and can be removed' do
    membership = supporting('Adam Adamczyk')

    get story_group_teachers_path(@story_group)

    assert_select '.gh-role', text: 'Nauczyciel wspomagający', count: 1
    assert_select 'a[href=?]',
                  confirm_destroy_story_group_teacher_path(@story_group, membership), count: 1
  end

  test 'the Dodano column is a plain date' do
    membership = supporting('Adam Adamczyk')

    get story_group_teachers_path(@story_group)

    assert_includes css_select('.gh-dt').map(&:text),
                    membership.created_at.to_date.strftime('%d.%m.%Y')
  end

  test 'the lead says who may delete the group' do
    get story_group_teachers_path(@story_group)

    assert_select '.gh-lead', /Grupę może usunąć tylko właściciel\./
  end

  # --- the add dialog -------------------------------------------------------

  test 'every candidate is rendered hidden, with the pool counted in the hint' do
    teacher('Adam Adamczyk')
    teacher('Bogdan Borek')

    get new_story_group_teacher_path(@story_group), headers: MODAL

    assert_select '.gh-tres[hidden]', 1
    assert_select '.gh-tr[hidden]', 3 # two candidates plus the owner
    assert_select "[data-teacher-picker-target='hint']",
                  'Wpisz co najmniej 2 znaki imienia, nazwiska albo e-maila. ' \
                  'W Twojej uczelni są 3 nauczyciele.'
  end

  test 'the search key is folded, so the browser can match without diacritics' do
    person = teacher('Łukasz Lis')

    get new_story_group_teacher_path(@story_group), headers: MODAL

    row = css_select('.gh-tr').find { |item| item.css('b').text == 'Łukasz Lis' }
    assert_equal "lukasz lis #{person.email.downcase}", row['data-teacher-picker-key']
  end

  test 'people already in the group wear a chip instead of a button' do
    supporting('Adam Adamczyk')
    teacher('Bogdan Borek')

    get new_story_group_teacher_path(@story_group), headers: MODAL

    rows = css_select('.gh-tr')
    inside = rows.select { |row| row.css('.gh-st2').any? }
                 .map { |row| row.css('b').text }

    assert_equal ['Adam Adamczyk', 'Zofia Zawadzka'], inside
    assert_select '.gh-tr button', 1
    assert_select '.gh-tr button[aria-label=?]', 'Dodaj Bogdan Borek'
  end

  # One form around the whole list: a form per candidate would be hundreds of
  # forms for one click.
  test 'the whole list sits in one form and each button carries its own id' do
    person = teacher('Adam Adamczyk')

    get new_story_group_teacher_path(@story_group), headers: MODAL

    assert_select 'form', 1
    assert_select 'button[name=?][value=?]', 'story_group_teacher[user_id]', person.id.to_s
  end

  test 'the university is printed only when the pool can span more than one' do
    person = teacher('Adam Adamczyk')

    get new_story_group_teacher_path(@story_group), headers: MODAL
    assert_select '.gh-tr-n small', text: person.email, count: 1

    sign_in_as FactoryBot.create(:user, role: :global_admin)
    get new_story_group_teacher_path(@story_group), headers: MODAL
    assert_select '.gh-tr-n small', text: "#{person.email}, Example university", count: 1
  end

  test 'a university with nobody else in it says so instead of showing a search' do
    @owner.update!(university_name: 'Lonely university')

    get new_story_group_teacher_path(@story_group), headers: MODAL

    assert_select '.gh-search', false
    assert_select '.gh-expl', /Nie ma kogo dodać/
  end

  # --- adding ---------------------------------------------------------------

  test 'adding names the person and leaves the dialog' do
    person = teacher('Adam Adamczyk')

    assert_difference('StoryGroupTeacher.count') do
      post story_group_teachers_path(@story_group),
           params: { story_group_teacher: { user_id: person.id } }, headers: MODAL
    end

    assert_turbo_redirected_to story_group_teachers_url(@story_group)
    assert_equal 'Dodano: Adam Adamczyk.', flash[:notice]
  end

  test 'adding somebody already in is refused on the field, not silently' do
    membership = supporting('Adam Adamczyk')

    assert_no_difference('StoryGroupTeacher.count') do
      post story_group_teachers_path(@story_group),
           params: { story_group_teacher: { user_id: membership.user_id } }, headers: MODAL
    end

    assert_response :unprocessable_content
    assert_select '.gh-err span', 'Ta osoba jest już w grupie.'
  end

  # --- removing -------------------------------------------------------------

  test 'the removal dialog says what survives and lands on Anuluj' do
    membership = supporting('Adam Adamczyk')

    get confirm_destroy_story_group_teacher_path(@story_group, membership), headers: MODAL

    assert_select '#gh-del-title', 'Usunąć Adam Adamczyk z grupy?'
    assert_select 'p', 'Straci dostęp do grupy. Nagrody, które przyznał, zostają u studentów.'
    assert_select '.gh-dlg-b button[autofocus]', 'Anuluj'
  end

  test 'removing takes the membership and names who left' do
    membership = supporting('Adam Adamczyk')

    assert_difference('StoryGroupTeacher.count', -1) do
      delete story_group_teacher_path(@story_group, membership), headers: MODAL
    end

    assert_turbo_redirected_to story_group_teachers_url(@story_group)
    assert_equal 'Usunięto z grupy: Adam Adamczyk.', flash[:notice]
  end

  # --- presentation ---------------------------------------------------------

  test 'every dialog carries exactly one modal frame, and none as a page' do
    membership = supporting('Adam Adamczyk')

    paths = [new_story_group_teacher_path(@story_group),
             confirm_destroy_story_group_teacher_path(@story_group, membership),]

    paths.each do |path|
      get path, headers: MODAL
      assert_select 'turbo-frame#modal', 1, "#{path} inside the dialog"

      # As a page the only modal frame is the layout's own, inside <dialog>.
      get path
      assert_select 'main#app-content turbo-frame#modal', false, "#{path} as a page"
      assert_select 'header.gh-hd', 1, "#{path} keeps the shell as a page"
    end
  end

  test 'a dialog opened as a page gets a surface, and in the dialog does not' do
    membership = supporting('Adam Adamczyk')

    paths = [new_story_group_teacher_path(@story_group),
             confirm_destroy_story_group_teacher_path(@story_group, membership),]

    paths.each do |path|
      get path
      assert_select 'main .gh-panel.gh-dlg-page', 1, "#{path} as a page sits on a panel"

      get path, headers: MODAL
      assert_select '.gh-dlg-page', false, "#{path} in the dialog needs no panel"
    end
  end

  test 'adding says so in a toast, not in a banner' do
    person = teacher('Adam Adamczyk')

    post story_group_teachers_path(@story_group),
         params: { story_group_teacher: { user_id: person.id } }, headers: MODAL
    get story_group_teachers_path(@story_group)

    assert_select '#gh-toasts template[data-toast-target=seed]', 'Dodano: Adam Adamczyk.'
    assert_select '#flash-messages', false
  end

  # --- authorization --------------------------------------------------------

  test 'a supporting teacher reads the list but is offered nothing to change' do
    membership = supporting('Adam Adamczyk')
    sign_in_as membership.user

    get story_group_teachers_path(@story_group)

    assert_response :success
    assert_select '.gh-trow', 3 # header, the owner, themselves — all readable
    assert_select '.gh-lead',
                  'Nauczyciele wspomagający pomagają prowadzić tę grupę. ' \
                  'Dodawać i usuwać nauczycieli może tylko właściciel grupy.'
    assert_select '.gh-phead .gh-btn', false
    assert_select 'a[href=?]',
                  confirm_destroy_story_group_teacher_path(@story_group, membership), count: 0
  end

  # Hiding the buttons is presentation; this is the part that actually holds.
  test 'a supporting teacher is refused every way of changing the list' do
    membership = supporting('Adam Adamczyk')
    outsider = teacher('Bogdan Borek')
    sign_in_as membership.user

    assert_no_difference('StoryGroupTeacher.count') do
      get new_story_group_teacher_path(@story_group), headers: MODAL
      assert_redirected_to root_path

      post story_group_teachers_path(@story_group),
           params: { story_group_teacher: { user_id: outsider.id } }, headers: MODAL
      assert_redirected_to root_path

      get confirm_destroy_story_group_teacher_path(@story_group, membership), headers: MODAL
      assert_redirected_to root_path

      delete story_group_teacher_path(@story_group, membership), headers: MODAL
      assert_redirected_to root_path
    end
  end

  # Admins reach every group, and this list is no exception.
  test 'an organization admin who owns nothing may still add and remove' do
    membership = supporting('Adam Adamczyk')
    person = teacher('Bogdan Borek')
    sign_in_as FactoryBot.create(:user, role: :organization_admin)

    get story_group_teachers_path(@story_group)
    assert_select '.gh-phead .gh-btn', 1

    assert_difference('StoryGroupTeacher.count') do
      post story_group_teachers_path(@story_group),
           params: { story_group_teacher: { user_id: person.id } }, headers: MODAL
    end

    assert_difference('StoryGroupTeacher.count', -1) do
      delete story_group_teacher_path(@story_group, membership), headers: MODAL
    end
  end

  test 'a student cannot reach the list' do
    student = FactoryBot.create(:user, role: :student)
    FactoryBot.create(:story_group_student, story_group: @story_group, user: student)
    sign_in_as student

    get story_group_teachers_path(@story_group)

    # ApplicationController rescues Pundit and bounces to the root rather than
    # confirming the group exists.
    assert_redirected_to root_path
  end
end
