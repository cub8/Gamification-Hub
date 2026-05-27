# frozen_string_literal: true

class ActivityGroupsController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!

  def index
    @activity_group_templates = policy_scope(@story_group.activity_group_templates)
                                .includes(activity_groups: :activity_group_categories)
    @open_collapse_id = cookies["activity_groups_#{@story_group.id}"]
  end

  def edit
    @activity_group = @story_group.activity_groups.find(params[:id])
  end

  def create
    template = @story_group.activity_group_templates.find(params.dig(:activity_group, :activity_group_template_id))
    name = params.dig(:activity_group, :name).presence || ActivityGroup.next_name_for_template(template)

    ActivityGroupBuilder.new(story_group: @story_group, template: template).build(name: name)

    redirect_to story_group_activity_groups_path(@story_group),
                notice: 'Activity group was successfully created.', status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to story_group_activity_groups_path(@story_group),
                alert: e.message, status: :see_other
  end

  def update
    @activity_group = @story_group.activity_groups.find(params[:id])

    if @activity_group.update(activity_group_params)
      if params[:partial_save].present?
        redirect_to edit_story_group_activity_group_path(@story_group, @activity_group),
                    status: :see_other
      else
        redirect_to story_group_activity_groups_path(@story_group),
                    notice: 'Activity group was successfully updated.', status: :see_other
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def create_bulk
    template = @story_group.activity_group_templates.find(params[:template_id])
    count = params[:count].to_i.clamp(1, 50)

    ActivityGroupBuilder.new(story_group: @story_group, template: template).build_many(count: count)

    redirect_to story_group_activity_groups_path(@story_group),
                notice: "#{count} activity group(s) created successfully.", status: :see_other
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

  def activity_group_params
    params.expect(
      activity_group: [
        :name,
        {
          activity_group_categories_attributes: [%i[
            id story_description didactic_description reward position _destroy
          ]],
        },
      ],
    )
  end
end
