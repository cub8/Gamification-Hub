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

  test 'import creates items from a valid file' do
    assert_difference('Item.count', 1) do
      post import_story_group_items_url(@story_group),
           params: { file: fixture_file_upload('items_import.csv', 'text/csv') }
    end

    assert_turbo_redirected_to story_group_items_url(@story_group)
  end

  test 'import redirects back with an alert for an unparseable file' do
    assert_no_difference('Item.count') do
      post import_story_group_items_url(@story_group),
           params: { file: fixture_file_upload('malformed_import.csv', 'text/csv') }
    end

    assert_turbo_redirected_to story_group_items_url(@story_group)
    assert_match(/nie udało się odczytać/i, flash[:alert])
  end
end
