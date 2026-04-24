# frozen_string_literal: true

require 'test_helper'

class ShopControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @current_user = FactoryBot.create(:user, role: :student)
    sign_in @current_user
    @story_group_student = FactoryBot.create(:story_group_student, user: @current_user, story_group: @story_group)
  end

  test 'student should get index' do
    get story_group_shop_index_url(@story_group)
    assert_response :success
  end

  test 'teacher should not get index' do
    sign_out
    @current_user = @teacher
    sign_in @current_user
    get story_group_shop_index_url(@story_group)
    assert_response :redirect
  end
end
