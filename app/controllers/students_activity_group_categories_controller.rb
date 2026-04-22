# frozen_string_literal: true

class StudentsActivityGroupCategoriesController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_activity_group

  def edit
    @categories = @activity_group.activity_group_categories
    @students   = @story_group.student_memberships.with_user.joins(:user).sort_by do |m|
      I18n.transliterate(m.user.full_name)
    end
    @completed  = StudentsActivityGroupCategory
                  .where(activity_group_category: @categories)
                  .pluck(:activity_group_category_id, :student_id)
                  .to_set
  end

  def update
    ActivityGroupRewardGranter.new(activity_group: @activity_group, story_group: @story_group)
                              .save(parsed_reward_params)

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

  def parsed_reward_params
    set = Set.new
    params.expect(completions: {}).each do |student_id, category_hash|
      category_hash.each_key { |category_id| set.add([category_id.to_i, student_id.to_i]) }
    end
    set
  rescue ActionController::ParameterMissing
    set
  end
end
