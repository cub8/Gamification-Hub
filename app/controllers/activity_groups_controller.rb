# frozen_string_literal: true

class ActivityGroupsController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!

  def index
    @activity_group_templates = policy_scope(@story_group.activity_group_templates)
                                .includes(activity_groups: :activity_group_categories)
  end

  def edit
    @activity_group = @story_group.activity_groups.find(params[:id])
  end

  def create
    template = @story_group.activity_group_templates.find(params.dig(:activity_group, :activity_group_template_id))
    @activity_group = @story_group.activity_groups.build(
      activity_group_template: template,
      name:                    ActivityGroup.next_name_for_template(template),
    )

    if @activity_group.save
      copy_categories_from_template(@activity_group, template)
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: 'Activity group was successfully created.', status: :see_other
    else
      redirect_to story_group_activity_groups_path(@story_group),
                  alert: @activity_group.errors.full_messages.to_sentence, status: :see_other
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

  def create_bulk
    template = @story_group.activity_group_templates.find(params[:template_id])
    count = params[:count].to_i.clamp(1, 50)

    ActivityGroupBulkBuilder.new(
      story_group: @story_group,
      template:    template,
      count:       count,
    ).build

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

  def copy_categories_from_template(group, template)
    template.categories.order(:position).each_with_index do |cat, idx|
      group.activity_group_categories.create!(
        story_description:    cat.story_description,
        didactic_description: cat.didactic_description,
        reward:               cat.reward,
        position:             idx,
      )
    end
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
