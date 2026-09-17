# frozen_string_literal: true

require 'test_helper'

class ActivityGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = FactoryBot.create(:user, :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @teacher)
    @template = FactoryBot.create(:activity_group_template, story_group: @story_group, base_name: 'Lab')
    @template_category = FactoryBot.create(:activity_group_template_category,
                                           activity_group_template: @template,
                                           didactic_description:    'Task 1',
                                           reward:                  10,
                                           position:                0,)
    @activity_group = FactoryBot.create(:activity_group,
                                        story_group:             @story_group,
                                        activity_group_template: @template,
                                        name:                    'Lab 1',)
    @category = FactoryBot.create(:activity_group_category, activity_group: @activity_group)
    sign_in @teacher
  end

  test 'should get index' do
    get story_group_activity_groups_url(@story_group)
    assert_response :success
  end

  test 'should get edit' do
    get edit_story_group_activity_group_url(@story_group, @activity_group)
    assert_response :success
  end

  # The "Utwórz arkusz" dialog. A GET now, where the Bootstrap screen rendered
  # three modals into the index whether or not anyone opened them.
  test 'should get the create dialog for a template' do
    get new_story_group_activity_group_url(@story_group, template_id: @template.id)

    assert_response :success
    assert_select 'h2', 'Nowy arkusz z szablonu Lab'
  end

  test 'should create activity group with auto-generated name' do
    assert_difference('ActivityGroup.count', 1) do
      post story_group_activity_groups_url(@story_group),
           params: { activity_group: { activity_group_template_id: @template.id } }
    end

    assert_equal 'Lab 2', ActivityGroup.last!.name
    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should create activity group with provided name' do
    assert_difference('ActivityGroup.count', 1) do
      post story_group_activity_groups_url(@story_group),
           params: { activity_group: { activity_group_template_id: @template.id, name: 'Custom Name' } }
    end

    assert_equal 'Custom Name', ActivityGroup.last!.name
  end

  # Bulk creation used to be a route of its own; it is the same form now, with
  # the mode the dialog's segmented control posts.
  test 'should create several groups when the dialog is in bulk mode' do
    assert_difference('ActivityGroup.count', 3) do
      post story_group_activity_groups_url(@story_group),
           params: {
             activity_group: { activity_group_template_id: @template.id, mode: 'many' },
             count:          3,
           }
    end

    assert_equal ['Lab 2', 'Lab 3', 'Lab 4'],
                 ActivityGroup.where(activity_group_template: @template).order(:id).last(3).map(&:name)
    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should copy categories from template on create' do
    post story_group_activity_groups_url(@story_group),
         params: { activity_group: { activity_group_template_id: @template.id } }
    group = ActivityGroup.last!

    assert_equal @template.categories.count, group.activity_group_categories.count
    assert_equal 'Task 1', group.activity_group_categories.first.didactic_description
    assert_equal 10, group.activity_group_categories.first.reward
  end

  test 'should update activity group' do
    patch story_group_activity_group_url(@story_group, @activity_group),
          params: { activity_group: { name: 'Updated Lab' } }

    assert_equal 'Updated Lab', @activity_group.reload.name
    assert_redirected_to story_group_activity_groups_url(@story_group)
  end

  test 'should refuse a sheet left without a single visible column' do
    patch story_group_activity_group_url(@story_group, @activity_group),
          params: {
            activity_group: {
              name:                                 'Lab 1',
              activity_group_categories_attributes: {
                '0' => { id: @category.id, _destroy: '1' },
              },
            },
          }

    assert_response :unprocessable_content
    assert_predicate @category.reload, :persisted?
  end

  # The index's "Zmienione kolumny" tag: stamped when this sheet's own columns
  # change, never when the template behind it does.
  test 'should stamp columns_modified_at only when the columns change' do
    patch story_group_activity_group_url(@story_group, @activity_group),
          params: { activity_group: { name: 'Renamed' } }
    assert_nil @activity_group.reload.columns_modified_at

    patch story_group_activity_group_url(@story_group, @activity_group),
          params: {
            activity_group: {
              activity_group_categories_attributes: {
                '0' => { id: @category.id, didactic_description: 'Something else' },
              },
            },
          }
    assert_not_nil @activity_group.reload.columns_modified_at
  end

  # DECISIONS.md:31. The UI offers hide instead of delete for an awarded
  # column; this is the rule behind it, because destroying the column would
  # take its awards with it and leave the currency unaccounted for.
  test 'should hide rather than destroy a column that has already been awarded' do
    student = FactoryBot.create(:story_group_student, story_group: @story_group,
                                                      user:        FactoryBot.create(:user),)
    FactoryBot.create(:students_activity_group_category, student: student, activity_group_category: @category)
    other = FactoryBot.create(:activity_group_category, activity_group: @activity_group, position: 1)

    assert_no_difference('ActivityGroupCategory.count') do
      patch story_group_activity_group_url(@story_group, @activity_group),
            params: {
              activity_group: {
                activity_group_categories_attributes: {
                  '0' => { id: @category.id, _destroy: '1' },
                },
              },
            }
    end

    assert_predicate @category.reload, :hidden?
    assert_not other.reload.hidden?
  end

  # Soft (DECISIONS.md:54): the sheet leaves the list, the currency it granted
  # stays with the students.
  test 'should soft delete activity group' do
    assert_no_difference('ActivityGroup.count') do
      delete story_group_activity_group_url(@story_group, @activity_group)
    end

    assert_predicate @activity_group.reload, :deleted?
    assert_empty @story_group.activity_groups.kept
  end

  test 'a deleted sheet is gone from the index and unreachable' do
    @activity_group.soft_delete!

    get story_group_activity_groups_url(@story_group)
    assert_response :success
    assert_select '.gh-ag-n b', false

    # ApplicationController turns the RecordNotFound into the app's own
    # "Nie znaleziono." rather than a bare 404.
    get edit_story_group_activity_group_url(@story_group, @activity_group)
    assert_redirected_to root_url
  end

  test 'should not access groups for story group not managed by teacher' do
    other_story_group = FactoryBot.create(:story_group)
    get story_group_activity_groups_url(other_story_group)
    assert_redirected_to root_url
  end

  test 'should not create group without authentication' do
    sign_out
    assert_no_difference('ActivityGroup.count') do
      post story_group_activity_groups_url(@story_group),
           params: { activity_group: { activity_group_template_id: @template.id } }
    end
  end
end
