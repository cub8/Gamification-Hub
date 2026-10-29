# frozen_string_literal: true

require 'test_helper'

class BadgesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    sign_in @teacher
  end

  test 'should create badge' do
    assert_difference('Badge.count') do
      post story_group_badges_url(@story_group),
           params: {
             badge: {
               name:                 'Achievement',
               story_description:    'An achievement badge',
               didactic_description: 'A badge for achieving something',
               discount:             10,
               icon_glyph:           'rabbit',
             },
           }
    end

    assert_redirected_to story_group_badges_url(@story_group)
  end

  test 'should not create badge for story group not owned by teacher' do
    other_teacher = FactoryBot.create(:user, role: :teacher)
    other_story_group = FactoryBot.create(:story_group, owner: other_teacher)

    post story_group_badges_url(other_story_group),
         params: {
           badge: {
             name:                 'Achievement',
             story_description:    'An achievement badge',
             didactic_description: 'A badge for achieving something',
             discount:             10,
           },
         }

    assert_redirected_to root_url
  end

  test 'should soft delete badge' do
    badge = FactoryBot.create(:badge, story_group: @story_group)

    assert_no_difference('Badge.count') do
      delete story_group_badge_url(@story_group, badge)
    end

    assert_predicate badge.reload, :deleted?
    assert_turbo_redirected_to story_group_badges_url(@story_group)
  end

  test 'should not create badge without authentication' do
    sign_out
    assert_no_difference('Badge.count') do
      post story_group_badges_url(@story_group),
           params: {
             badge: {
               name:                 'Achievement',
               story_description:    'An achievement badge',
               didactic_description: 'A badge for achieving something',
               discount:             10,
               icon_glyph:           'rabbit',
             },
           }
    end
  end

  test 'should get new_import' do
    get new_import_story_group_badges_url(@story_group)
    assert_response :success
  end

  test 'import shows a preview of the parsed file without persisting anything' do
    assert_no_difference('Badge.count') do
      post import_story_group_badges_url(@story_group),
           params: { file: fixture_file_upload('badges_import.csv', 'text/csv') }
    end

    assert_response :success
    assert_select 'input[name="setup[badges][0][name]"][value="Zuch"]'
  end

  test 'import shows an inline error for an unparseable file instead of redirecting' do
    assert_no_difference('Badge.count') do
      post import_story_group_badges_url(@story_group),
           params: { file: fixture_file_upload('malformed_import.csv', 'text/csv') }
    end

    assert_response :unprocessable_content
    assert_select '.gh-field-error', text: /niepoprawny format/i
  end

  test 'import catches a blank required field at preview time, before any confirm step' do
    assert_no_difference('Badge.count') do
      post import_story_group_badges_url(@story_group),
           params: { file: fixture_file_upload('blank_name_badges_import.csv', 'text/csv') }
    end

    assert_response :unprocessable_content
    assert_select '.gh-field-error', text: /podaj nazwę odznaki/i
  end

  test 'confirm_import persists the previewed badges' do
    assert_difference('Badge.count', 2) do
      post confirm_import_story_group_badges_url(@story_group),
           params: {
             setup: {
               badges: {
                 '0' => { name: 'Zuch', didactic_description: 'Opis dydaktyczny', discount: '5', icon_glyph: 'rabbit' },
                 '1' => { name: 'Asceta', didactic_description: 'Inny opis', discount: '10', icon_glyph: 'shield' },
               },
             },
           }
    end

    assert_turbo_redirected_to story_group_badges_url(@story_group)
  end
end
