# frozen_string_literal: true

require 'test_helper'

class RanksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    sign_in @teacher
  end

  test 'should create rank' do
    assert_difference('Rank.count') do
      post story_group_ranks_url(@story_group),
           params: {
             rank: {
               name:                    'Gold',
               discount:                20,
               required_currency_value: 500,
               icon_glyph:              'chev1',
             },
           }
    end

    assert_redirected_to story_group_ranks_url(@story_group)
  end

  test 'should not create rank for story group not owned by teacher' do
    other_teacher = FactoryBot.create(:user, role: :teacher)
    other_story_group = FactoryBot.create(:story_group, owner: other_teacher)

    post story_group_ranks_url(other_story_group),
         params: {
           rank: {
             name:                    'Gold',
             discount:                20,
             required_currency_value: 500,
           },
         }

    assert_redirected_to root_url
  end

  test 'should destroy rank' do
    rank = FactoryBot.create(:rank, story_group: @story_group)

    assert_difference('Rank.count', -1) do
      delete story_group_rank_url(@story_group, rank)
    end

    assert_turbo_redirected_to story_group_ranks_url(@story_group)
  end

  test 'should not create rank without authentication' do
    sign_out
    assert_no_difference('Rank.count') do
      post story_group_ranks_url(@story_group),
           params: {
             rank: {
               name:                    'Gold',
               discount:                20,
               required_currency_value: 500,
               icon_glyph:              'chev1',
             },
           }
    end
  end

  test 'should get new_import' do
    get new_import_story_group_ranks_url(@story_group)
    assert_response :success
  end

  test 'import shows a preview of the parsed file without persisting anything' do
    assert_no_difference('Rank.count') do
      post import_story_group_ranks_url(@story_group),
           params: { file: fixture_file_upload('ranks_import.csv', 'text/csv') }
    end

    assert_response :success
    assert_select 'input[name="setup[ranks][0][name]"][value="Srebro"]'
  end

  test 'import shows an inline error for an unparseable file instead of redirecting' do
    assert_no_difference('Rank.count') do
      post import_story_group_ranks_url(@story_group),
           params: { file: fixture_file_upload('malformed_import.csv', 'text/csv') }
    end

    assert_response :unprocessable_content
    assert_select '.gh-field-error', text: /niepoprawny format/i
  end

  test 'import catches a duplicate rank threshold at preview time, before any confirm step' do
    assert_no_difference('Rank.count') do
      post import_story_group_ranks_url(@story_group),
           params: { file: fixture_file_upload('duplicate_threshold_ranks_import.csv', 'text/csv') }
    end

    assert_response :unprocessable_content
    assert_select '.gh-field-error', text: /nie mogą mieć tego samego progu/i
  end

  test 'confirm_import persists the previewed ranks' do
    assert_difference('Rank.count', 2) do
      post confirm_import_story_group_ranks_url(@story_group),
           params: {
             setup: {
               ranks: {
                 '0' => { name: 'Srebro', threshold: '200', discount: '5', icon_glyph: 'chev1' },
                 '1' => { name: 'Złoto', threshold: '500', discount: '15', icon_glyph: 'chev2' },
               },
             },
           }
    end

    assert_turbo_redirected_to story_group_ranks_url(@story_group)
  end
end
