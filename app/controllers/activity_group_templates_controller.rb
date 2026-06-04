# frozen_string_literal: true

class ActivityGroupTemplatesController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!

  def index
    @activity_group_templates = policy_scope(@story_group.activity_group_templates)
  end

  def show
    @activity_group_template = @story_group.activity_group_templates.find(params[:id])
    render json: {
      id:         @activity_group_template.id,
      base_name:  @activity_group_template.base_name,
      categories: @activity_group_template.categories.order(:position).map do |c|
        {
          story_description:    c.story_description,
          didactic_description: c.didactic_description,
          reward:               c.reward,
          position:             c.position,
        }
      end,
    }
  end

  def new
    @activity_group_template = @story_group.activity_group_templates.build
    @activity_group_template.categories.build
  end

  def edit
    @activity_group_template = @story_group.activity_group_templates.find(params[:id])
  end

  def create
    @activity_group_template = @story_group.activity_group_templates.build(activity_group_template_params)

    if @activity_group_template.save
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: 'Pomyślnie utworzono szablon grupy aktywności.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @activity_group_template = @story_group.activity_group_templates.find(params[:id])

    if @activity_group_template.update(activity_group_template_params)
      if params[:partial_save].present?
        redirect_to edit_story_group_activity_group_template_path(@story_group, @activity_group_template),
                    status: :see_other
      else
        redirect_to story_group_activity_groups_path(@story_group),
                    notice: 'Pomyślnie zaktualizowano szablon grupy aktywności.', status: :see_other
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @activity_group_template = @story_group.activity_group_templates.find(params[:id])
    @activity_group_template.destroy!

    redirect_to story_group_activity_groups_path(@story_group),
                notice: 'Pomyślnie usunięto szablon grupy aktywności.', status: :see_other
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def activity_group_template_params
    params.expect(
      activity_group_template: [
        :base_name,
        {
          categories_attributes: [%i[
            id story_description didactic_description reward position _destroy
          ]],
        },
      ],
    )
  end
end
