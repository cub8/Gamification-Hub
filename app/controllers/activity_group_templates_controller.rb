# frozen_string_literal: true

class ActivityGroupTemplatesController < ApplicationController
  include StoryGroupAuthorization
  include RedesignLayout

  # Same split as ranks and sheets: the delete confirmation is a dialog,
  # creating and editing are pages carrying a preview column.
  layout -> { @in_modal ? false : 'redesign' }

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_presentation, only: :confirm_destroy
  before_action :set_template, only: %i[edit update destroy confirm_destroy]

  # GET /story_groups/:story_group_id/activity_group_templates/new
  def new
    @activity_group_template = @story_group.activity_group_templates.build

    # The mockup opens with two rows, the first already filled in: a template
    # with one category is not a grading table, and an empty first row gives
    # nothing to copy the shape from.
    @activity_group_template.categories.build(didactic_description: 'Obecność', reward: 2, position: 0)
    @activity_group_template.categories.build(reward: 1, position: 1)
  end

  # GET /story_groups/:story_group_id/activity_group_templates/:id/edit
  def edit
    @sheet_names = sheet_names_for(@activity_group_template)
  end

  # GET /story_groups/:story_group_id/activity_group_templates/:id/confirm_destroy
  def confirm_destroy
    @sheet_names = sheet_names_for(@activity_group_template)
  end

  # POST /story_groups/:story_group_id/activity_group_templates
  def create
    @activity_group_template = @story_group.activity_group_templates.build(template_params)

    if @activity_group_template.save(context: :settings)
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: "Utworzono szablon „#{@activity_group_template.base_name}”.", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /story_groups/:story_group_id/activity_group_templates/:id
  #
  # Nothing here reaches into sheets that already exist (DECISIONS.md:30) —
  # they hold their own copies of the columns. This only changes what the next
  # "Utwórz arkusz" stamps out.
  def update
    @activity_group_template.assign_attributes(template_params)

    if @activity_group_template.save(context: :settings)
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: 'Zapisano szablon. Nowe arkusze dostaną te kategorie.', status: :see_other
    else
      @sheet_names = sheet_names_for(@activity_group_template)
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/:story_group_id/activity_group_templates/:id
  #
  # Soft, and it stops at the template: the sheets made from it stay on the
  # index under no heading of their own only because they keep their own
  # template_id, so they simply stop being listed here. That is what the
  # confirmation promises — "utworzone z niego arkusze zostają".
  def destroy
    name = @activity_group_template.base_name
    @activity_group_template.soft_delete!

    redirect_outside_turbo_frame story_group_activity_groups_path(@story_group),
                                 notice: "Usunięto szablon „#{name}”. Utworzone z niego arkusze zostają."
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

  # Named in the edit screen's info banner ("Laboratoria 1–5 zostają bez
  # zmian"), so the teacher can see exactly what the edit is NOT touching.
  def sheet_names_for(template)
    template.activity_groups.kept.order(:id).pluck(:name)
  end

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
