# frozen_string_literal: true

require 'test_helper'

# "Ocenianie" — the grading table (mockup #/t/grade,
# js-expanded/30-main.js:169-193 and the review dialog at :215-222).
#
# The screen the handoff left for last: sticky columns, three cell states and
# an action that cannot be undone.
class GradingRedesignSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher, currency_name: 'marchewek')
    @template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Laboratoria')
    FactoryBot.create(:activity_group_template_category, activity_group_template: @template,
                                                         didactic_description: 'Obecność', reward: 2,
                                                         story_description: 'Stawił się na mostku', position: 0,)
    FactoryBot.create(:activity_group_template_category, activity_group_template: @template,
                                                         didactic_description: 'Pomoc innym', reward: 3, position: 1,)
    @sheet = ActivityGroupBuilder.new(story_group: @story_group, template: @template).build(name: 'Laboratoria 5')
    @obecnosc, @pomoc = @sheet.activity_group_categories.to_a
    @ada = student!('Ada Kowalska')
    @bartek = student!('Bartek Nowak')
    sign_in @teacher
  end

  def student!(name)
    FactoryBot.create(:story_group_student, story_group: @story_group, nickname: nil,
                                            user: FactoryBot.create(:user, full_name: name),)
  end

  def grade_path = edit_story_group_activity_group_students_activity_group_categories_path(@story_group, @sheet)

  def award!(category, student)
    FactoryBot.create(:students_activity_group_category, student: student, activity_group_category: category)
  end

  # --- layout ---------------------------------------------------------------

  test 'the grading table renders inside the redesign chrome' do
    get grade_path

    assert_response :success
    assert_select '.gh-shell header.gh-hd'
    assert_select 'link[href*=redesign]'
    assert_select 'link[href*=application]', false
    assert_no_match(/data-bs-/, response.body)
  end

  test 'the page head names the sheet and what is about to happen' do
    get grade_path

    assert_select '.gh-crumbs a', 'Arkusze ocen'
    assert_select '.gh-crumbs span', 'Laboratoria'
    assert_select 'h1.gh-h1', 'Laboratoria 5'
    assert_select 'p.gh-lead',
                  /2 kategorie, 2 studentów\. Zaznacz, kto zdobył nagrody, a przed przyznaniem/
  end

  test 'the legend names all three cell states' do
    get grade_path

    assert_select 'ul.gh-legend[aria-label=Legenda] li', 3
    assert_select '.gh-legend', /Puste/
    assert_select '.gh-legend', /Zaznaczone teraz/
    assert_select '.gh-legend', /Przyznane, nie do cofnięcia/
  end

  # --- the grid -------------------------------------------------------------

  test 'categories are columns and students are rows' do
    get grade_path

    assert_select 'table.gh-grid thead th.gh-th-stu', 'Student'
    assert_select 'table.gh-grid thead th.gh-th-sum', 'Razem'
    assert_equal(['Obecność', 'Pomoc innym'], css_select('.gh-thc .gh-thn').map { |th| th.text.strip })
    assert_select 'tbody tr[data-grading-target=row]', 2
    # The avatar initials share the cell, so read past them.
    assert_equal(['Ada Kowalska', 'Bartek Nowak'],
                 css_select('tbody th.gh-td-stu').map { |th| th.text.split("\n").map(&:strip).last },)
  end

  # Never the nickname: the sheet is the teacher naming a person before an award
  # they cannot take back, so a pseudonym in this column is the one thing that
  # could put a reward on the wrong row.
  test 'the sheet and its review dialog name students by their real name' do
    @ada.update!(nickname: 'Kapitan Marchewka')

    get grade_path

    assert_equal(['Ada Kowalska', 'Bartek Nowak'],
                 css_select('tbody th.gh-td-stu').map { |th| th.text.split("\n").map(&:strip).last },)
    assert_select '.gh-rv .gh-rv-n', /Ada Kowalska/
    assert_no_match(/Kapitan Marchewka/, response.body)
  end

  # Sorted by the real name too, or the order would not match what is printed.
  test 'a nickname does not move a row in the sheet order' do
    @bartek.update!(nickname: 'Admirał')

    get grade_path

    assert_equal(['Ada Kowalska', 'Bartek Nowak'],
                 css_select('tbody th.gh-td-stu').map { |th| th.text.split("\n").map(&:strip).last },)
  end

  test 'the story description is the column tooltip and appears nowhere else' do
    get grade_path

    assert_select '.gh-thn[title=?]', 'Stawił się na mostku'
    assert_select 'td', { text: 'Stawił się na mostku', count: 0 }
  end

  test 'each column carries its reward and a select-all button' do
    get grade_path

    assert_equal(['+2', '+3'], css_select('.gh-thc .gh-cost b').map { |b| b.text.strip })
    assert_select '.gh-colbtn[data-grading-column-param=?][title=?]',
                  @obecnosc.id.to_s, 'Zaznacz całą kolumnę'
  end

  # Three states (DECISIONS.md:31). The third is not a control: it has no
  # input, so there is nothing to post and nothing to take back.
  test 'an empty cell is a checkbox and an awarded cell is not' do
    award!(@obecnosc, @ada)
    get grade_path

    assert_select 'input[name=?]', "completions[#{@ada.id}][#{@pomoc.id}]"
    assert_select 'input[name=?]', "completions[#{@ada.id}][#{@obecnosc.id}]", false

    assert_select 'span.gh-cell--awarded[title=?]', 'Przyznane, nie można cofnąć' do
      assert_select '[aria-label=?]', 'Ada Kowalska, Obecność: przyznane'
    end
    assert_select 'label.gh-cell input[aria-label=?]', 'Ada Kowalska, Pomoc innym: puste'
  end

  test 'the Razem column shows what a student has already collected here' do
    award!(@obecnosc, @ada)
    award!(@pomoc, @ada)
    get grade_path

    assert_select 'tbody tr:first-child td.gh-td-sum .gh-sum-a', '5'
    assert_select 'tbody tr:last-child td.gh-td-sum .gh-sum-a', '0'
    assert_select '.gh-sum-p[hidden]', 2
  end

  test 'a hidden column is out of the table entirely' do
    @pomoc.update!(hidden: true)
    get grade_path

    assert_equal(['Obecność'], css_select('.gh-thc .gh-thn').map { |th| th.text.strip })
    assert_select 'input[name=?]', "completions[#{@ada.id}][#{@pomoc.id}]", false
  end

  # The CSS gives the page its shape through this exact nesting: .gh-gradeview
  # is a flex column, the form inside it carries the height down, and the three
  # bands are its children. The form is easy to overlook as "just a wrapper" —
  # it is a box in the height chain, and when it was left out of it the award
  # bar was pushed off the bottom of the screen and grading could not be
  # submitted at all.
  test 'the three bands are laid out the way the stylesheet expects' do
    get grade_path

    assert_select '.gh-gradeview > section.gh-ghead'
    assert_select '.gh-gradeview > form.gh-gform' do
      assert_select '> section.gh-board > .gh-board-scroll > table.gh-grid'
      assert_select '> section.gh-abar'
    end

    # Order matters: the bar is the last band, under the board.
    bands = css_select('.gh-gform > section').map { |node| node['class'].split.last }
    assert_equal %w[gh-board gh-abar], bands
  end

  # .gh-s-a belongs to student_list.css, where it is a flex row of buttons.
  # Reusing the mockup's own class name here turned the two numbers into
  # stacked blocks.
  test 'the Razem column does not borrow the student list class names' do
    get grade_path

    assert_select 'td.gh-td-sum .gh-sum-a'
    assert_select 'td.gh-td-sum .gh-s-a', false
    assert_select 'td.gh-td-sum .gh-s-p', false
  end

  # --- the award bar --------------------------------------------------------

  test 'the award bar starts empty and is a live region' do
    get grade_path

    assert_select 'section.gh-abar[aria-live=polite]' do
      assert_select '[data-grading-target=barEmpty]',
                    'Nic nie jest zaznaczone. Kliknij pola studentów, którzy zdobyli nagrody.'
      assert_select '[data-grading-target=barActive][hidden]'
      # Useless until the controller is running: without it, unticking a box
      # is the clearing mechanism.
      assert_select 'button[data-grading-target=clear][hidden]', 'Wyczyść zaznaczenia'
      assert_select 'button[type=submit]', 'Przejrzyj i przyznaj'
    end
  end

  # --- the review dialog ----------------------------------------------------

  test 'the review dialog holds the whole matrix, hidden' do
    get grade_path

    assert_select 'dialog.gh-dialog--review' do
      assert_select '.gh-warn',
                    /Po zatwierdzeniu nie da się tego cofnąć\. Sprawdź listę, zanim przyznasz nagrody\./
      assert_select 'li[data-grading-target=reviewRow][hidden]', 2
      assert_select 'span[data-grading-target=reviewChip][hidden]', 4
      assert_select 'span[data-gh-student=?][data-gh-column=?]', @ada.id.to_s, @obecnosc.id.to_s
    end
  end

  test 'the review dialog focuses the safe button and submits the real form' do
    get grade_path

    assert_select '.gh-dialog--review .gh-dlg-b' do
      assert_select 'button:first-child[autofocus]', /Wróć do edycji/
      assert_select 'button[type=submit][form=gh-grade-form]', /Przyznaj/
    end
  end

  test 'a cell already awarded has no chip to offer in the dialog' do
    award!(@obecnosc, @ada)
    get grade_path

    assert_select 'span[data-gh-student=?][data-gh-column=?]', @ada.id.to_s, @obecnosc.id.to_s, false
    assert_select 'span[data-grading-target=reviewChip]', 3
  end

  # --- awarding -------------------------------------------------------------

  test 'awarding grants the marked cells and says so' do
    assert_difference('CurrencyTransaction.count', 2) do
      patch story_group_activity_group_students_activity_group_categories_path(@story_group, @sheet),
            params: { completions: { @ada.id.to_s => { @obecnosc.id.to_s => '1', @pomoc.id.to_s => '1' } } }
    end

    assert_redirected_to grade_path
    assert_equal 'Przyznano 5 marchewek 1 studentowi.', flash[:notice]
    assert_equal 5, @ada.reload.current_currency - 1
    assert_equal 5, @ada.total_currency - 1
  end

  # The cells the last save granted play the stamp animation once, staggered.
  test 'the cells just granted are marked for the stamp' do
    patch story_group_activity_group_students_activity_group_categories_path(@story_group, @sheet),
          params: { completions: { @ada.id.to_s => { @obecnosc.id.to_s => '1' } } }
    follow_redirect!

    assert_select 'span.gh-cell--awarded.gh-cell--stamp', 1
  end

  # There is no un-grant, by design: a pair missing from the submission is not
  # a revocation.
  test 'leaving an awarded cell out of the submission does not take it back' do
    award!(@obecnosc, @ada)

    assert_no_difference('StudentsActivityGroupCategory.count') do
      patch story_group_activity_group_students_activity_group_categories_path(@story_group, @sheet),
            params: { completions: { @bartek.id.to_s => {} } }
    end

    assert_predicate @obecnosc.students_activity_group_categories.where(student: @ada), :exists?
  end

  test 'a hidden column cannot be awarded even by hand' do
    @pomoc.update!(hidden: true)

    assert_no_difference('StudentsActivityGroupCategory.count') do
      patch story_group_activity_group_students_activity_group_categories_path(@story_group, @sheet),
            params: { completions: { @ada.id.to_s => { @pomoc.id.to_s => '1' } } }
    end
  end

  test 'submitting nothing grants nothing and says nothing happened' do
    assert_no_difference('StudentsActivityGroupCategory.count') do
      patch story_group_activity_group_students_activity_group_categories_path(@story_group, @sheet)
    end

    assert_equal 'Nie zaznaczono żadnego pola.', flash[:notice]
  end

  # --- empty states and the phone ------------------------------------------

  test 'a sheet with no columns names the next action' do
    @sheet.activity_group_categories.destroy_all
    get grade_path

    assert_select '.gh-gm h2', 'Ten arkusz nie ma żadnej kolumny'
    assert_select 'table.gh-grid', false
  end

  test 'a group with no students names the next action' do
    @story_group.student_memberships.destroy_all
    get grade_path

    assert_select '.gh-gm h2', 'W tej grupie nie ma jeszcze studentów'
    assert_select 'table.gh-grid', false
  end

  test 'the phone gets an explanation instead of an unreadable table' do
    get grade_path

    assert_select '.gh-grade-mobile .gh-gmob' do
      assert_select 'h1', 'Laboratoria 5'
      assert_select '.gh-lead', /Ocenianie w tabeli działa na komputerze/
      assert_select 'a', 'Wróć na start'
    end
  end
end
