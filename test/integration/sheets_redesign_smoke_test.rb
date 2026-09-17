# frozen_string_literal: true

require 'test_helper'

# "Arkusze ocen" — the sheet index (mockup #/t/sheets) and the "Utwórz arkusz"
# dialog (30-ag.js:57-65), converted to the redesign layout.
class SheetsRedesignSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher, currency_name: 'marchewek')
    sign_in @teacher
  end

  def template!(base_name: 'Laboratoria', rewards: [2, 3])
    template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: base_name)
    rewards.each_with_index do |reward, index|
      FactoryBot.create(:activity_group_template_category,
                        activity_group_template: template,
                        didactic_description:    "Kategoria #{index + 1}",
                        reward:                  reward,
                        position:                index,)
    end
    template
  end

  def sheet!(template, name)
    ActivityGroupBuilder.new(story_group: @story_group, template: template).build(name: name)
  end

  def award!(category)
    student = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                      user:        FactoryBot.create(:user),)
    FactoryBot.create(:students_activity_group_category, student: student, activity_group_category: category)
  end

  # --- layout ---------------------------------------------------------------

  test 'the sheet index renders inside the redesign chrome' do
    template!
    get story_group_activity_groups_path(@story_group)

    assert_response :success
    assert_select '.gh-shell header.gh-hd'
    assert_select 'link[href*=redesign]'
    assert_select 'link[href*=application]', false
    assert_no_match(/data-bs-/, response.body)
  end

  test 'the sidebar marks Arkusze ocen as the current destination' do
    get story_group_activity_groups_path(@story_group)

    assert_select 'aside.gh-sb a.gh-nl.gh-nl--on[href=?][aria-current=page]',
                  story_group_activity_groups_path(@story_group), 'Arkusze ocen'
  end

  # The screen is called "Arkusze ocen" now, not "Grupy aktywności"
  # (DECISIONS.md:29). The models keep their names.
  test 'the page head carries the settled wording' do
    get story_group_activity_groups_path(@story_group)

    assert_select 'h1.gh-h1', 'Arkusze ocen'
    assert_select 'p.gh-lead', 'Arkusze pogrupowane według szablonów. Najnowsze są na górze.'
    assert_select '.gh-rowb a', 'Nowy szablon'
    assert_no_match(/Grupy aktywności/i, response.body)
  end

  # --- template panels ------------------------------------------------------

  test 'each template is a flat panel with its reward ceiling' do
    template = template!(rewards: [2, 3])
    get story_group_activity_groups_path(@story_group)

    assert_select 'section.gh-tpl[aria-labelledby=?]', "gh-tpl-#{template.id}" do
      assert_select 'h2', 'Laboratoria'
      assert_select '.gh-tpl-meta', /2 kategorie, do 5 marchewek na studenta za arkusz\./
      assert_select 'a', 'Edytuj szablon'
      assert_select 'a', 'Utwórz arkusz'
    end
  end

  # No accordion and no dropdown menus: the Bootstrap screen hid the sheets
  # behind a collapse whose open panel was remembered in a cookie.
  test 'the sheets are listed without a collapse' do
    template = template!
    sheet!(template, 'Laboratoria 1')
    get story_group_activity_groups_path(@story_group)

    assert_select 'ul.gh-agl li.gh-ag', 1
    assert_select '[data-controller*=collapse-memory]', false
    assert_select '[data-bs-toggle]', false
  end

  test 'sheets read newest first and only the newest gets the primary Oceń' do
    template = template!
    sheet!(template, 'Laboratoria 1')
    sheet!(template, 'Laboratoria 2')
    get story_group_activity_groups_path(@story_group)

    names = css_select('ul.gh-agl li.gh-ag .gh-ag-n b').map(&:text)
    assert_equal ['Laboratoria 2', 'Laboratoria 1'], names

    buttons = css_select('ul.gh-agl li.gh-ag .gh-ag-a a.gh-btn')
    assert_not_includes buttons.first['class'], 'gh-btn--sec'
    assert_includes buttons.last['class'], 'gh-btn--sec'
  end

  test 'a sheet reports how much it has already paid out' do
    template = template!
    sheet = sheet!(template, 'Laboratoria 1')
    award!(sheet.activity_group_categories.first)

    get story_group_activity_groups_path(@story_group)
    assert_select '.gh-ag-s', 'Przyznano 1 nagrodę'
  end

  test 'a sheet nobody has graded says so' do
    template = template!
    sheet!(template, 'Laboratoria 1')

    get story_group_activity_groups_path(@story_group)
    assert_select '.gh-ag-s', 'Jeszcze nic nie przyznano'
  end

  # "Zmienione kolumny" — this sheet's own columns were edited, which is not
  # the same thing as the template having changed since.
  test 'only a sheet whose own columns were edited carries the modified tag' do
    template = template!
    sheet = sheet!(template, 'Laboratoria 1')

    get story_group_activity_groups_path(@story_group)
    assert_select '.gh-tag--mod', false

    sheet.update!(columns_modified_at: Time.current)
    get story_group_activity_groups_path(@story_group)
    assert_select '.gh-tag--mod', 'Zmienione kolumny'
  end

  test 'a template with no sheets names the next action' do
    template!
    get story_group_activity_groups_path(@story_group)

    assert_select '.gh-expl', 'Z tego szablonu nie utworzono jeszcze arkuszy.'
  end

  test 'a group with no templates gets the empty panel' do
    get story_group_activity_groups_path(@story_group)

    assert_select '.gh-gm h2', 'Nie masz jeszcze żadnego szablonu'
    assert_select 'section.gh-tpl', false
  end

  test 'a soft deleted template drops off the index and takes no sheets with it' do
    template = template!
    sheet!(template, 'Laboratoria 1')
    template.soft_delete!

    get story_group_activity_groups_path(@story_group)
    assert_select 'section.gh-tpl', false
    assert_equal 1, @story_group.activity_groups.kept.count
  end

  # --- the create dialog ----------------------------------------------------

  test 'the create dialog offers both modes in one form' do
    template = template!
    get new_story_group_activity_group_path(@story_group, template_id: template.id)

    assert_response :success
    assert_select 'h2', 'Nowy arkusz z szablonu Laboratoria'
    assert_select 'p', /Każdy arkusz dostanie 2 kategorie z szablonu\./
    assert_select '[data-controller=sheet-create]' do
      assert_select '.gh-seg3[role=radiogroup][aria-label=?]', 'Ile arkuszy'
      assert_select 'input[name=?][value=one][checked]', 'activity_group[mode]'
      assert_select 'input[name=?][value=many]', 'activity_group[mode]'
    end
  end

  # The chips come from the same call that names the records, so the preview
  # cannot promise a name the save does not use.
  test 'the dialog previews the names the sheets will actually get' do
    template = template!
    sheet!(template, 'Laboratoria 1')
    get new_story_group_activity_group_path(@story_group, template_id: template.id)

    assert_select 'input[name=?][value=?]', 'activity_group[name]', 'Laboratoria 2'
    names = css_select('.gh-names span').map(&:text).map(&:strip)
    assert_equal 'Laboratoria 2', names.first
    assert_equal 'Laboratoria 3', names.second

    # Only the first few are shown; the rest wait for the stepper.
    shown = css_select('.gh-names span').reject { |chip| chip.attributes.key?('hidden') }
    assert_equal 3, shown.size
  end

  # The rows the last request created are highlighted once, so a run of eight
  # shows you which eight are new.
  test 'sheets just created are highlighted on the way back' do
    template = template!

    post story_group_activity_groups_path(@story_group),
         params: { activity_group: { activity_group_template_id: template.id, mode: 'many' }, count: 2 }
    follow_redirect!

    assert_select 'li.gh-ag--fresh', 2
    assert_select '.gh-toasts template', /Utworzono: Laboratoria 1 – Laboratoria 2\./

    # Only once: a reload is not a creation.
    get story_group_activity_groups_path(@story_group)
    assert_select 'li.gh-ag--fresh', false
  end

  test 'the dialog renders as a page when it is not in the modal frame' do
    template = template!
    get new_story_group_activity_group_path(@story_group, template_id: template.id)

    # The layout's own empty `modal` frame is always there; what matters is
    # that the dialog's body is not inside it.
    assert_select 'section.gh-panel.gh-dlg-page'
    assert_select '.gh-shell'
    assert_select 'turbo-frame#modal h2', false
  end

  test 'the dialog renders into the modal frame when asked for' do
    template = template!
    get new_story_group_activity_group_path(@story_group, template_id: template.id),
        headers: { 'Turbo-Frame' => 'modal' }

    assert_select 'turbo-frame#modal'
    assert_select '.gh-shell', false
  end
end
