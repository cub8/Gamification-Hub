# frozen_string_literal: true

class ActivityGroupTemplatesController < ApplicationController
  include StoryGroupAuthorization
  include CsvImportable

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_presentation, only: :confirm_destroy
  before_action :set_template, only: %i[edit update destroy confirm_destroy]

  def new
    @activity_group_template = @story_group.activity_group_templates.build

    @activity_group_template.categories.build(didactic_description: t('activity_group_templates.default_category'),
                                              reward:               2,
                                              position:             0,)
    @activity_group_template.categories.build(reward: 1, position: 1)
  end

  def edit
    @sheet_names = sheet_names_for(@activity_group_template)
  end

  def confirm_destroy
    @sheet_names = sheet_names_for(@activity_group_template)
  end

  def create
    @activity_group_template = @story_group.activity_group_templates.build(template_params)

    if @activity_group_template.save(context: :settings)
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: t('activity_group_templates.flash.created', name: @activity_group_template.base_name),
                  status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @activity_group_template.assign_attributes(template_params)

    if @activity_group_template.save(context: :settings)
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: t('activity_group_templates.flash.updated'), status: :see_other
    else
      @sheet_names = sheet_names_for(@activity_group_template)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    name = @activity_group_template.base_name
    @activity_group_template.soft_delete!

    redirect_outside_turbo_frame story_group_activity_groups_path(@story_group),
                                 notice: t('activity_group_templates.flash.destroyed', name: name)
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_template
    @activity_group_template = @story_group.activity_group_templates.kept.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def sheet_names_for(template)
    template.activity_groups.kept.order(:id).pluck(:name)
  end

  def import_resource_key = :templates
  def import_redirect_path = story_group_activity_groups_path(@story_group)

  def template_params
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
