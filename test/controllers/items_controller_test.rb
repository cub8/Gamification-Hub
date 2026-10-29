# frozen_string_literal: true

require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    sign_in @teacher
  end

  test 'should get new_import' do
    get new_import_story_group_items_url(@story_group)
    assert_response :success
  end

  test 'import shows a preview of the parsed file without persisting anything' do
    assert_no_difference('Item.count') do
      post import_story_group_items_url(@story_group),
           params: { file: fixture_file_upload('items_import.csv', 'text/csv') }
    end

    assert_response :success
    assert_select 'input[name="setup[items][0][name]"][value="Konsultacja"]'
  end

  test 'import shows an inline error for an unparseable file instead of redirecting' do
    assert_no_difference('Item.count') do
      post import_story_group_items_url(@story_group),
           params: { file: fixture_file_upload('malformed_import.csv', 'text/csv') }
    end

    assert_response :unprocessable_content
    assert_select '.gh-field-error', text: /niepoprawny format/i
  end

  test 'confirm_import persists the previewed item, resolving an existing rank reference' do
    rank = FactoryBot.create(:rank, story_group: @story_group)

    assert_difference('Item.count', 1) do
      post confirm_import_story_group_items_url(@story_group),
           params: {
             setup: {
               items: {
                 '0' => {
                   name:                 'Konsultacja',
                   price:                '15',
                   didactic_description: 'Opis',
                   icon_glyph:           'chat',
                   can_buy_at_0_lives:   '0',
                   unlock_rank:          "existing:#{rank.id}",
                 },
               },
             },
           }
    end

    assert_turbo_redirected_to story_group_items_url(@story_group)
    assert_equal rank, Item.last.unlock_rank
  end
end
