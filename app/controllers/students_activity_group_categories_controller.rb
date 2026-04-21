# frozen_string_literal: true

class StudentsActivityGroupCategoriesController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_activity_group

  def edit
    @categories = @activity_group.activity_group_categories
    @students   = @story_group.student_memberships.with_user
    @completed  = StudentActivityGroupCategory
                  .where(activity_group_category: @categories)
                  .pluck(:activity_group_category_id, :student_id)
                  .to_set
  end

  def update
    ActivityGroupRewardGranter.new(activity_group: @activity_group, story_group: @story_group)
                              .save(parse_completed_pairs(params[:completions]))

    redirect_to edit_story_group_activity_group_students_activity_group_categories_path(@story_group, @activity_group),
                notice: 'Rewards saved.', status: :see_other
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_activity_group
    @activity_group = @story_group.activity_groups.find(params[:activity_group_id])
  end

  def parse_completed_pairs(completions_params)
    set = Set.new
    (completions_params || {}).each do |student_id, cat_hash|
      cat_hash.each_key { |cat_id| set.add([cat_id.to_i, student_id.to_i]) }
    end
    set
  end
end
