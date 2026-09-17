# frozen_string_literal: true

require 'test_helper'

# The three editor screens: "Nowy szablon arkusza", "Edytuj szablon arkusza"
# and "Ustawienia arkusza" (mockup #/t/sheet-template-new, -edit and
# #/t/sheet-settings, all of js-expanded/30-ag.js:42-50).
#
# One partial serves all three, so most of what is asserted here is the
# difference between them.
class SheetFormsRedesignSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher, currency_name: 'marchewek')
    @template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Laboratoria')
    FactoryBot.create(:activity_group_template_category, activity_group_template: @template,
                                                         didactic_description: 'Obecność', reward: 2, position: 0,)
    FactoryBot.create(:activity_group_template_category, activity_group_template: @template,
                                                         didactic_description: 'Pomoc innym', reward: 3, position: 1,)
    sign_in @teacher
  end

  def sheet!(name = 'Laboratoria 1')
    ActivityGroupBuilder.new(story_group: @story_group, template: @template).build(name: name)
  end

  def award!(category)
    student = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                      user:        FactoryBot.create(:user),)
    FactoryBot.create(:students_activity_group_category, student: student, activity_group_category: category)
  end

  # --- layout ---------------------------------------------------------------

  test 'the editor is a page on the redesign layout, not a modal' do
    get new_story_group_activity_group_template_path(@story_group)

    assert_response :success
    assert_select '.gh-shell header.gh-hd'
    assert_select 'link[href*=redesign]'
    assert_select 'link[href*=application]', false
    assert_no_match(/data-bs-/, response.body)
    # DECISIONS.md:26 — create and edit are pages. The Bootstrap version
    # rendered both into a shared `modal` frame.
    assert_select '.gh-wiz .gh-fcol'
    assert_select '.gh-wiz .gh-pcol'
  end

  test 'each screen carries its own heading and crumb trail' do
    {
      new_story_group_activity_group_template_path(@story_group)             =>
                                                                                ['Nowy szablon arkusza',
                                                                                 'Nowy szablon',],
      edit_story_group_activity_group_template_path(@story_group, @template) =>
                                                                                ['Edytuj szablon arkusza',
                                                                                 'Laboratoria',],
      edit_story_group_activity_group_path(@story_group, sheet!)             =>
                                                                                ['Ustawienia arkusza',
                                                                                 'Laboratoria 1',],
    }.each do |path, (heading, crumb)|
      get path

      assert_select 'h1.gh-h1', heading
      assert_select '.gh-crumbs a', 'Arkusze ocen'
      assert_select '.gh-crumbs span', crumb
    end
  end

  # --- the preview column ---------------------------------------------------

  test 'the preview shows the grading table header it is describing' do
    get edit_story_group_activity_group_template_path(@story_group, @template)

    assert_select 'aside.gh-pcol[aria-label=?]', 'Podgląd' do
      assert_select '.gh-pv h3', 'Nagłówek tabeli ocen'
      assert_select '.gh-gprev table.gh-grid thead th', 3 # Student + two columns
      assert_equal(['Obecność', 'Pomoc innym'], css_select('.gh-gprev .gh-thn').map { |th| th.text.strip })
      assert_select '.gh-hint', /Najedź na nagłówek/
    end
  end

  test 'the summary line counts only what will be in the table' do
    get edit_story_group_activity_group_template_path(@story_group, @template)

    assert_select '[data-sheet-form-target=summaryCount]', '2 kolumny'
    assert_select '[data-sheet-form-target=summaryMax]', '5'
  end

  # --- the category rows ----------------------------------------------------

  test 'a new template opens with two rows, the first filled in' do
    get new_story_group_activity_group_template_path(@story_group)

    assert_select 'ul.gh-cats li.gh-cat', 2
    assert_select 'h2.gh-h3', 'Kategorie nagród'
    assert_select 'button', 'Dodaj kategorię'
    assert_select 'input[value=Obecność]'
  end

  test 'sheet settings calls the same rows columns' do
    get edit_story_group_activity_group_path(@story_group, sheet!)

    assert_select 'h2.gh-h3', 'Kolumny w tabeli ocen'
    assert_select 'button', 'Dodaj kolumnę'
  end

  test 'rows are wired for reordering by pointer and by keyboard' do
    get new_story_group_activity_group_template_path(@story_group)

    assert_select 'ul.gh-cats[data-controller=sortable-rows]'
    assert_select '.gh-handle[title=?]', 'Przeciągnij, aby zmienić kolejność'
    assert_select 'button[aria-label=?]', 'Przesuń wyżej'
    assert_select 'button[aria-label=?]', 'Przesuń niżej'
  end

  # Removal is a checkbox, so it posts whether or not the controller ran — and
  # it is pending until save either way.
  test 'an unawarded column offers removal and nothing else' do
    get edit_story_group_activity_group_path(@story_group, sheet!)

    # Scoped to the list: the blank row the "Dodaj" button clones lives in a
    # <template> beside it and carries the same markup.
    assert_select 'ul.gh-cats input[data-sheet-form-target=destroy]', 2
    assert_select 'ul.gh-cats input[data-sheet-form-target=hide]', false
    assert_select '.gh-lockn', false
  end

  # DECISIONS.md:31 — a column that has paid out can be hidden, never removed.
  test 'an awarded column offers hiding instead, and says why' do
    sheet = sheet!
    awarded = sheet.activity_group_categories.first
    award!(awarded)

    get edit_story_group_activity_group_path(@story_group, sheet)

    assert_select 'li#gh-cat-0 input[data-sheet-form-target=hide]'
    assert_select 'li#gh-cat-0 input[data-sheet-form-target=destroy]', false
    assert_select 'li#gh-cat-0 .gh-lockn',
                  /Przyznano 1 nagrodę\.\s*Kolumny nie można usunąć, można ją ukryć\./
    assert_select 'li#gh-cat-1 input[data-sheet-form-target=destroy]'
  end

  test 'a hidden column says so and leaves the preview' do
    sheet = sheet!
    sheet.activity_group_categories.first.update!(hidden: true)

    get edit_story_group_activity_group_path(@story_group, sheet)

    assert_select 'li.gh-cat--hidden'
    assert_select '.gh-tag--hidden', 'Ukryta w tabeli ocen'
    assert_equal(['Pomoc innym'], css_select('.gh-gprev .gh-thn').map { |th| th.text.strip })
    assert_select '[data-sheet-form-target=summaryCount]', '1 kolumna'
  end

  # A column added in sheet settings has no template category behind it.
  test 'a column that exists only in this sheet is tagged' do
    sheet = sheet!
    sheet.activity_group_categories.create!(didactic_description: 'Prezentacja', reward: 3, position: 2)

    get edit_story_group_activity_group_path(@story_group, sheet)
    assert_select '.gh-tag--only', 'Tylko w tym arkuszu'
  end

  # --- the banners ----------------------------------------------------------

  test 'editing a template says which sheets it will not touch' do
    sheet!('Laboratoria 1')
    sheet!('Laboratoria 2')

    get edit_story_group_activity_group_template_path(@story_group, @template)
    assert_select '.gh-info b', 'Zmiany dotyczą tylko arkuszy utworzonych od teraz.'
    assert_select '.gh-info', /Laboratoria 1 – Laboratoria 2 zostają bez zmian\./
  end

  test 'sheet settings says how much has already been paid out of it' do
    sheet = sheet!
    award!(sheet.activity_group_categories.first)

    get edit_story_group_activity_group_path(@story_group, sheet)
    assert_select '.gh-info b', 'W tym arkuszu przyznano już 1 nagrodę.'
    assert_select '.gh-info', /Szablon Laboratoria się nie zmienia\./
  end

  test 'a new template has no delete section and no banner' do
    get new_story_group_activity_group_template_path(@story_group)

    assert_select 'h2.gh-h3', { text: 'Usuwanie', count: 0 }
    assert_select '.gh-info', false
  end

  # --- the action bar and the discard guard ---------------------------------

  test 'the action bar reports its state and offers a way out' do
    get edit_story_group_activity_group_template_path(@story_group, @template)

    assert_select '.gh-wbar a.gh-linkbtn', 'Anuluj'
    assert_select '[data-sheet-form-target=dirty]', 'Brak zmian'
    assert_select '.gh-wbar button[type=submit]', 'Zapisz zmiany'
  end

  test 'creating says create' do
    get new_story_group_activity_group_template_path(@story_group)

    assert_select '.gh-wbar button[type=submit]', 'Utwórz szablon'
    assert_select '[data-sheet-form-target=dirty]', false
  end

  test 'leaving with unsaved changes is guarded by a dialog' do
    get edit_story_group_activity_group_template_path(@story_group, @template)

    assert_select 'dialog[data-sheet-form-target=discard]' do
      assert_select 'h2', 'Odrzucić zmiany?'
      # The safe button comes first and takes the focus.
      assert_select '.gh-dlg-b button:first-child[autofocus]', 'Wróć do edycji'
      assert_select '.gh-dlg-b button:last-child', 'Odrzuć zmiany'
    end
  end

  # --- deletion -------------------------------------------------------------

  test 'the sheet delete confirmation promises the awards survive' do
    sheet = sheet!
    award!(sheet.activity_group_categories.first)

    get confirm_destroy_story_group_activity_group_path(@story_group, sheet)

    assert_select 'h2', 'Usunąć arkusz „Laboratoria 1”?'
    assert_select 'p', 'Arkusz zniknie z listy, a przyznane nagrody zostają u studentów i w ich historii.'
    assert_select '.gh-info', /Przyznano z niego 1 nagrodę\./
    # As a page the safe way out is a link back to the settings screen; in the
    # dialog it is a button that closes it.
    assert_select '.gh-dlg-b a.gh-btn--sec', 'Anuluj'
  end

  test 'the template delete confirmation promises the sheets survive' do
    sheet!('Laboratoria 1')

    get confirm_destroy_story_group_activity_group_template_path(@story_group, @template)

    assert_select 'h2', 'Usunąć szablon „Laboratoria”?'
    assert_select 'p', 'Szablon zniknie z listy, a utworzone z niego arkusze zostają.'
    assert_select '.gh-info', /1 arkusz zostaje bez zmian: Laboratoria 1/
  end
end
