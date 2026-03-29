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
               name: 'Gold',
               description: 'A gold rank',
             },
           }
    end

    assert_redirected_to story_group_url(@story_group)
  end

  test 'should not create rank for story group not owned by teacher' do
    other_teacher = FactoryBot.create(:user, role: :teacher)
    other_story_group = FactoryBot.create(:story_group, owner: other_teacher)

    post story_group_ranks_url(other_story_group),
         params: {
           rank: {
             name: 'Gold',
             description: 'A gold rank',
           },
         }

    assert_redirected_to root_url
  end

  test 'should destroy rank' do
    rank = FactoryBot.create(:rank, story_group: @story_group)

    assert_difference('Rank.count', -1) do
      delete story_group_rank_url(@story_group, rank)
    end

    assert_redirected_to story_group_url(@story_group)
  end

  test 'should not create rank without authentication' do
    sign_out
    assert_no_difference('Rank.count') do
      post story_group_ranks_url(@story_group),
           params: {
             rank: {
               name: 'Gold',
               description: 'A gold rank',
             },
           }
    end
  end
end