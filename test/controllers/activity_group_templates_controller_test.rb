# frozen_string_literal: true

require 'test_helper'

class ActivityGroupTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab')
    @category = FactoryBot.create(:activity_group_template_category,
                                  activity_group_template: @template,
                                  didactic_description:    'Task 1',
                                  reward:                  10,
                                  position:                0,)
    sign_in @teacher
  end

  test 'should get new' do
    get new_story_group_activity_group_template_url(@story_group)

    assert_response :success
    # The mockup opens with two rows, the first already filled in.
    assert_select 'ul.gh-category-list li.gh-category-row', 2
  end

  test 'should get edit' do
    get edit_story_group_activity_group_template_url(@story_group, @template)
    assert_response :success
  end

  test 'should create activity_group_template' do
    assert_difference('ActivityGroupTemplate.count', 1) do
      post story_group_activity_group_templates_url(@story_group),
           params: {
             activity_group_template: {
               base_name:             'Homework',
               categories_attributes: [
                 { didactic_description: 'Task 1', reward: 10, position: 0 },
               ],
             },
           }
    end

    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should refuse a template with no categories' do
    assert_no_difference('ActivityGroupTemplate.count') do
      post story_group_activity_group_templates_url(@story_group),
           params: { activity_group_template: { base_name: 'Homework' } }
    end

    assert_response :unprocessable_content
  end

  test 'should refuse a reward below one' do
    assert_no_difference('ActivityGroupTemplate.count') do
      post story_group_activity_group_templates_url(@story_group),
           params: {
             activity_group_template: {
               base_name:             'Homework',
               categories_attributes: [{ didactic_description: 'Task 1', reward: 0, position: 0 }],
             },
           }
    end

    assert_response :unprocessable_content
  end

  test 'should update activity_group_template' do
    patch story_group_activity_group_template_url(@story_group, @template),
          params: { activity_group_template: { base_name: 'Updated Lab' } }

    assert_redirected_to story_group_activity_groups_url(@story_group)
    assert_equal 'Updated Lab', @template.reload.base_name
  end

  # DECISIONS.md:30. The sheets hold their own copies of the columns, so
  # editing the template cannot reach them.
  test 'editing a template leaves the sheets already stamped from it alone' do
    sheet = ActivityGroupBuilder.new(story_group: @story_group, template: @template).build(name: 'Lab 1')

    patch story_group_activity_group_template_url(@story_group, @template),
          params: {
            activity_group_template: {
              base_name:             'Lab',
              categories_attributes: {
                '0' => {
                  id:                   @category.id,
                  didactic_description: 'Renamed',
                  reward:               3,
                  position:             0,
                },
              },
            },
          }

    assert_equal 'Task 1', sheet.activity_group_categories.first.didactic_description
    assert_equal 10, sheet.activity_group_categories.first.reward
  end

  # Soft (DECISIONS.md:54), and it stops at the template.
  test 'should soft delete activity_group_template and keep its sheets' do
    sheet = ActivityGroupBuilder.new(story_group: @story_group, template: @template).build(name: 'Lab 1')

    assert_no_difference(%w[ActivityGroupTemplate.count ActivityGroup.count]) do
      delete story_group_activity_group_template_url(@story_group, @template)
    end

    assert_predicate @template.reload, :deleted?
    assert_not sheet.reload.deleted?
    assert_empty @story_group.activity_group_templates.kept
  end

  test 'should not access templates for story group not managed by teacher' do
    other = FactoryBot.create(:story_group)
    other_template = FactoryBot.create(:activity_group_template, story_group: other)

    get edit_story_group_activity_group_template_url(other, other_template)
    assert_redirected_to root_url
  end

  test 'should not create template without authentication' do
    sign_out
    assert_no_difference('ActivityGroupTemplate.count') do
      post story_group_activity_group_templates_url(@story_group),
           params: { activity_group_template: { base_name: 'Lab' } }
    end
  end
end
