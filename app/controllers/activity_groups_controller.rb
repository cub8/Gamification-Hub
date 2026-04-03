# frozen_string_literal: true

class ActivityGroupsController < ApplicationController
  before_action :set_story_group
  before_action :authorize
  before_action :set_templates, only: %i[new edit create update]

  def index
    @activity_groups = @story_group.activity_groups.includes(:activity_group_categories)
  end

  def new
    @activity_group = @story_group.activity_groups.build
  end

  def edit
    @activity_group = @story_group.activity_groups.find(params[:id])
  end

  def create
    @activity_group = @story_group.activity_groups.build(activity_group_params)

    if @activity_group.save
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: 'Activity group was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @activity_group = @story_group.activity_groups.find(params[:id])

    if @activity_group.update(activity_group_params)
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: 'Activity group was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @activity_group = @story_group.activity_groups.find(params[:id])
    @activity_group.destroy!

    redirect_to story_group_activity_groups_path(@story_group),
                notice: 'Activity group was successfully destroyed.', status: :see_other
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_templates
    @templates = @story_group.activity_group_templates
  end

  def authorize
    return if @current_user.has_access_to_story_group?(@story_group)

    redirect_to root_path, alert: 'Not found'
  end

  def activity_group_params
    params.require(:activity_group).permit(
      :name,
      activity_group_categories_attributes: %i[
        id story_description didactic_description reward position _destroy
      ]
    )
  end
end
