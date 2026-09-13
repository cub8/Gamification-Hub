# frozen_string_literal: true

require 'test_helper'

class JoinControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @invite = FactoryBot.create(:story_group_invite, story_group: @story_group)
    @student = FactoryBot.create(:user, role: :student)
  end

  test 'should join story_group' do
    sign_in @student

    assert_difference('StoryGroupStudent.count') do
      post join_index_url, params: { code: @invite.code }
    end

    # The confirmation step renders in place; it is "Gotowe" that leaves for
    # the group, so this is a 200 rather than the old turbo redirect.
    assert_response :success
    assert_select '.gh-dlg-b a[href=?]', story_group_path(@story_group), 'Gotowe'
  end

  test 'should detect max_uses' do
    @invite.update!(uses: 10, max_uses: 10)
    sign_in @student

    assert_no_difference('StoryGroupStudent.count') do
      post join_index_url, params: { code: @invite.code }
    end

    assert_response :unprocessable_content
    assert_select '.gh-err span', /maksymalna liczba osób/
  end
end
