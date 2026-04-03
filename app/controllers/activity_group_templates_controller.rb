# frozen_string_literal: true

class ActivityGroupTemplatesController < ApplicationController
  before_action :set_story_group
  before_action :authorize

  def index
    @activity_group_templates = @story_group.activity_group_templates
  end

  def show
    @activity_group_template = @story_group.activity_group_templates.find(params[:id])
    render json: {
      id: @activity_group_template.id,
      base_name: @activity_group_template.base_name,
      categories: @activity_group_template.activity_group_template_categories.order(:position).map do |c|
        {
          story_description: c.story_description,
          didactic_description: c.didactic_description,
          reward: c.reward,
          position: c.position
        }
      end
    }
  end

  def new
    @activity_group_template = @story_group.activity_group_templates.build
    @activity_group_template.activity_group_template_categories.build
  end

  def edit
    @activity_group_template = @story_group.activity_group_templates.find(params[:id])
  end

  def create
    @activity_group_template = @story_group.activity_group_templates.build(activity_group_template_params)

    if @activity_group_template.save
      redirect_to story_group_activity_group_templates_path(@story_group),
                  notice: 'Activity group template was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @activity_group_template = @story_group.activity_group_templates.find(params[:id])

    if @activity_group_template.update(activity_group_template_params)
      redirect_to story_group_activity_group_templates_path(@story_group),
                  notice: 'Activity group template was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @activity_group_template = @story_group.activity_group_templates.find(params[:id])
    @activity_group_template.destroy!

    redirect_to story_group_activity_group_templates_path(@story_group),
                notice: 'Activity group template was successfully destroyed.', status: :see_other
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def authorize
    return if @current_user.has_access_to_story_group?(@story_group)

    redirect_to root_path, alert: 'Not found'
  end

  def activity_group_template_params
    params.require(:activity_group_template).permit(
      :base_name,
      activity_group_template_categories_attributes: %i[
        id story_description didactic_description reward position _destroy
      ]
    )
  end
end
