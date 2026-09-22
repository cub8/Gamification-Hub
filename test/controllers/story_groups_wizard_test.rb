# frozen_string_literal: true

require 'test_helper'

# The creation wizard: StoryGroupsController#new / #preset_preview / #create /
# #created. The plain CRUD around it lives in story_groups_controller_test.rb.
class StoryGroupsWizardTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    sign_in @teacher
  end

  def group_params(overrides = {})
    { name: 'Zakon Algorytmów', currency_name: 'Złotych Monet' }.merge(overrides)
  end

  # ---- the form ------------------------------------------------------------

  test 'the wizard renders four steps and its stepper' do
    get new_story_group_path

    assert_response :success
    assert_select 'nav.gh-stepper button.gh-stp', 4
    assert_select '[data-group-wizard-target="panel"]', 4
    assert_select 'form[enctype="multipart/form-data"]'
  end

  test 'both image pickers are on the form, so an upload can be cropped' do
    get new_story_group_path

    assert_select '[data-controller="image-crop"]', 2
    assert_select 'input[name="story_group[icon_glyph]"]'
    assert_select 'input[name="story_group[currency_icon_glyph]"]'
  end

  # One name, not the mockup's three declensions (the schema has one column).
  test 'asks for a single currency name' do
    get new_story_group_path

    assert_select 'input[name="story_group[currency_name]"]', 1
  end

  test 'ranking starts off, with its mode picker hidden' do
    get new_story_group_path

    assert_select 'input[name="story_group[ranking_enabled]"][type=checkbox][checked]', false
    assert_select '[data-group-wizard-target="rankingMode"][hidden]'
  end

  # .gh-inp is the TEXT INPUT shell and stretches a native select across the
  # form; .gh-sel is the octagon select the rest of the app uses.
  test 'the ranking mode picker uses the select shell, not the input shell' do
    get new_story_group_path

    assert_select '.gh-sel select[name="story_group[ranking_mode]"]'
    assert_select '.gh-sel .fa-chevron-down'
    assert_select '.gh-inp select', false
  end

  # Both themes at once, so a mark that vanishes on one table colour is caught
  # before the group exists. The "W zdaniach" panel was dropped.
  test 'step 2 previews the currency on a light and a dark table' do
    get new_story_group_path

    assert_select '.gh-cprev .gh-cmini', 2
    assert_select '.gh-cmini.gh-theme--light'
    assert_select '.gh-cmini.gh-theme--dark'
    assert_select '.gh-cmini .gh-bal'
    assert_select '.gh-cmini .gh-cost'
    assert_no_match(/W zdaniach/, response.body)
  end

  # ---- step 4's preset -----------------------------------------------------

  test 'preset_preview renders the scaled set' do
    get preset_preview_story_groups_path(pack: 'fantasy', classes: 12, currency_name: 'Monet')

    assert_response :success
    assert_select 'turbo-frame#starter_pack'
    assert_select '.gh-rrow', 5 + 6 + 7 + 8
    assert_select 'input[name="setup[ranks][1][value]"][value="20"]'
    assert_select 'input[name="setup[items][6][value]"][value="79"]'
    assert_match 'Giermek', response.body
  end

  # An unchecked box posts nothing, so every row needs its hidden companion or
  # a removal would be indistinguishable from an untouched row.
  test 'every preset row posts a keep value even when unchecked' do
    get preset_preview_story_groups_path(pack: 'neutral', classes: 12)

    assert_select 'input[type=hidden][name="setup[badges][0][keep]"][value="0"]'
    assert_select 'input[type=checkbox][name="setup[badges][0][keep]"][checked]'
  end

  # .gh-rgrid is two columns filling row-major, so this order is what puts
  # ranks and badges on the top row and items and categories beneath.
  test 'the preset zones read ranks, badges, items, categories' do
    get preset_preview_story_groups_path(pack: 'neutral', classes: 12)

    assert_equal(['Rangi', 'Odznaki', 'Przedmioty w sklepie', 'Kategorie zajęć'],
                 css_select('.gh-rz > h3').map { |node| node.text.split("\n").map(&:strip).find(&:present?) },)
  end

  # The coin, not the currency's name in words, and no stray leading "+".
  # The unit still has to be readable, so it moves into the aria-label.
  test 'item and category rows show the coin beside the number' do
    get preset_preview_story_groups_path(pack: 'neutral', classes: 12, currency_name: 'Monet')

    assert_select '.gh-rv2 .gh-tok[style=?]', '--gh-s: 20px', count: 7 + 8
    assert_select '.gh-rv2 .gh-tok [data-group-wizard-target="markBox"]', count: 7 + 8
    assert_select '.gh-rv2 .gh-k', false
    assert_select 'input[aria-label=?]', 'Obecność: nagroda w Monet'

    css_select('.gh-rv2').each do |cell|
      assert_not_includes cell.text, '+', 'a value cell still carries a leading plus'
    end
  end

  # The frame arrives after the icon was picked, so nothing would fill those
  # coins without the controller being told to re-render.
  test 'the preset frame asks the wizard to refresh once it loads' do
    get new_story_group_path

    assert_select 'turbo-frame#starter_pack[data-action=?]',
                  'turbo:frame-load->group-wizard#refresh'
  end

  test 'preset_preview survives a hand-edited query' do
    get preset_preview_story_groups_path(pack: 'nonsense', classes: 'abc')

    assert_response :success
  end

  # ---- creating ------------------------------------------------------------

  test 'the manual path creates an empty group' do
    assert_difference('StoryGroup.count', 1) do
      post story_groups_path, params: { story_group: group_params, setup: { path: 'manual' } }
    end

    group = StoryGroup.last
    assert_redirected_to created_story_group_path(group)
    assert_equal 0, group.ranks.count
    assert_equal 0, group.items.count
    assert_equal 0, group.activity_group_templates.count
  end

  test 'the quick path creates the whole set with the group' do
    assert_difference(['StoryGroup.count', 'ActivityGroupTemplate.count'], 1) do
      assert_difference('Rank.count', 5) do
        assert_difference('Badge.count', 6) do
          assert_difference('Item.count', 7) do
            post story_groups_path,
                 params: {
                   story_group: group_params,
                   setup:       { path: 'quick', pack: 'scifi', classes: '12' },
                 }
          end
        end
      end
    end

    group = StoryGroup.last
    assert_redirected_to created_story_group_path(group)
    assert_equal 'Kadet', group.ranks.by_threshold.first.name
    assert_equal 8, group.activity_group_templates.first.categories.count
  end

  test 'the quick path honours removals and retyped numbers' do
    post story_groups_path,
         params: {
           story_group: group_params,
           setup:       {
             path:    'quick',
             pack:    'neutral',
             classes: '12',
             items:   {
               '0' => { keep: '1', value: '99' },
               '6' => { keep: '0' },
             },
           },
         }

    group = StoryGroup.last
    assert_equal 6, group.items.count
    assert_equal 99, group.items.find_by(name: '+5 minut do wejściówki').price
    assert_nil group.items.find_by(name: '+0.5 oceny końcowej')
  end

  test 'the wizard can turn the ranking on' do
    post story_groups_path,
         params: {
           story_group: group_params(ranking_enabled: '1', ranking_mode: 'full'),
           setup:       { path: 'manual' },
         }

    group = StoryGroup.last
    assert_predicate group, :ranking_enabled?
    assert_predicate group, :ranking_full?
  end

  # ---- failures ------------------------------------------------------------

  test 'a group without a name re-renders the wizard and creates nothing' do
    assert_no_difference('StoryGroup.count') do
      post story_groups_path,
           params: { story_group: group_params(name: ''), setup: { path: 'manual' } }
    end

    assert_response :unprocessable_content
    assert_select 'nav.gh-stepper'
  end

  # The group and the pack share one transaction, so a pack that cannot be
  # built must not leave a group behind.
  test 'a pack that cannot be built takes the group with it' do
    assert_no_difference(['StoryGroup.count', 'Rank.count']) do
      post story_groups_path,
           params: {
             story_group: group_params,
             setup:       {
               path:    'quick',
               pack:    'neutral',
               classes: '12',
               ranks:   { '1' => { keep: '1', value: '40' } },
             },
           }
    end

    assert_response :unprocessable_content
    assert_select '.gh-err', /tego samego progu/
  end

  # ---- the success screen --------------------------------------------------

  test 'the success screen counts what was created and hides the join code' do
    post story_groups_path,
         params: {
           story_group: group_params,
           setup:       { path: 'quick', pack: 'neutral', classes: '12' },
         }
    follow_redirect!

    assert_response :success
    assert_select '.gh-okv'
    assert_match '5 rang', response.body
    assert_match '7 przedmiotów', response.body
    assert_select '.gh-code-big', false
  end

  # ApplicationController turns a Pundit refusal into a redirect, not a raise.
  test 'a stranger cannot see another teacher s success screen' do
    other = FactoryBot.create(:story_group, owner: FactoryBot.create(:user, role: :teacher))

    get created_story_group_path(other)

    assert_redirected_to root_path
  end
end
