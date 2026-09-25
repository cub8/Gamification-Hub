# frozen_string_literal: true

require 'test_helper'

# The group's artwork as the table behind every in-group screen
# (mockup 10-core.js:342 — `.tbg` + `.ttint` inside the content well).
#
# One branch in layouts/application.html.haml covers every nested controller,
# so this tests the branch rather than each screen.
class GroupBackgroundTest < ActionDispatch::IntegrationTest
  PNG = Base64.decode64(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  )

  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    sign_in @teacher
  end

  test 'a group with preset art blurs it behind the page' do
    group = FactoryBot.create(:story_group, owner: @teacher, icon_glyph: 'castle')

    get story_group_path(group)

    assert_response :success
    assert_select '.gh-content-well .gh-group-cover-bg'
    assert_select '.gh-content-well .gh-group-cover-tint'
    assert_select '.gh-content-well .gh-cover-pattern', false
    assert_match(/background-image:url\([^)]*castle/, response.body)
  end

  test 'an uploaded cover is used the same way' do
    group = FactoryBot.create(:story_group, owner: @teacher, icon_glyph: nil)
    group.icon.attach(io: StringIO.new(PNG), filename: 'art.png', content_type: 'image/png')

    get story_group_path(group)

    assert_select '.gh-content-well .gh-group-cover-bg'
    assert_select '.gh-content-well .gh-cover-pattern', false
  end

  # The fallback the octagon texture has always been.
  test 'a group with no art keeps the texture' do
    group = FactoryBot.create(:story_group, owner: @teacher, icon_glyph: nil)

    get story_group_path(group)

    assert_select '.gh-content-well .gh-cover-pattern--inset'
    assert_select '.gh-content-well .gh-group-cover-bg', false
  end

  # A retired preset key must fall back rather than render an empty frame.
  test 'an unknown preset key falls back to the texture' do
    group = FactoryBot.create(:story_group, owner: @teacher)
    group.update_column(:icon_glyph, 'retired')

    get story_group_path(group)

    assert_select '.gh-content-well .gh-cover-pattern--inset'
    assert_select '.gh-content-well .gh-group-cover-bg', false
  end

  test 'the background follows into the nested screens' do
    group = FactoryBot.create(:story_group, owner: @teacher, icon_glyph: 'waves')

    [story_group_ranks_path(group),
     story_group_badges_path(group),
     story_group_items_path(group),
     edit_story_group_path(group),].each do |path|
      get path

      assert_response :success
      assert_select '.gh-content-well .gh-group-cover-bg', 1, "no background on #{path}"
    end
  end

  # Out of a group there is no group art to show.
  test 'the group index keeps the texture' do
    get story_groups_path

    assert_select '.gh-cover-pattern'
    assert_select '.gh-group-cover-bg', false
  end

  # The wizard asks for the layer up front and fills it from Stimulus as the
  # teacher picks a tile, so it ships hidden rather than absent.
  test 'the wizard renders an empty background layer to paint into' do
    get new_story_group_path

    assert_select '.gh-content-well .gh-group-cover-bg[hidden]'
    assert_select '[data-group-art-layer]'
  end

  # Paired with the positive case, so this cannot pass by the tab bar simply
  # never rendering in tests.
  test 'the wizard hides the mobile tab bar that other screens show' do
    get story_groups_path
    assert_select 'nav.gh-mobile-tabbar', 1

    get new_story_group_path
    assert_select 'nav.gh-mobile-tabbar', false
  end
end
