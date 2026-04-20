# frozen_string_literal: true

class StudentsActivityGroupCategoriesController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_activity_group

  def show
    @categories = @activity_group.activity_group_categories
    @students   = @story_group.student_memberships.with_user
    @completed  = StudentActivityGroupCategory
                    .where(activity_group_category: @categories)
                    .pluck(:activity_group_category_id, :student_id)
                    .to_set
  end

  def update
    category = @activity_group.activity_group_categories.find(params[:category_id])
    student  = @story_group.student_memberships.find(params[:student_id])

    ActiveRecord::Base.transaction do
      if params[:completed] == '1'
        record = StudentActivityGroupCategory.find_or_create_by(
          activity_group_category_id: category.id,
          student_id:                 student.id,
        )
        if record.previously_new_record?
          student.increment!(:current_currency, category.reward)
          student.increment!(:total_currency, category.reward)
        end
      else
        record = StudentActivityGroupCategory.find_by(
          activity_group_category_id: category.id,
          student_id:                 student.id,
        )
        if record
          record.destroy!
          student.decrement!(:current_currency, category.reward)
          student.decrement!(:total_currency, category.reward)
        end
      end
    end

    head :ok
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_activity_group
    @activity_group = @story_group.activity_groups.find(params[:activity_group_id])
  end
end
