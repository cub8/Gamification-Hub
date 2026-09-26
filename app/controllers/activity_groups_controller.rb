# frozen_string_literal: true

class ActivityGroupsController < ApplicationController
  include StoryGroupAuthorization

  # "Utwórz arkusz" and the two delete confirmations are dialogs. Sheet
  # settings is a PAGE (DECISIONS.md:26) — it carries the grading-table preview
  # beside the column list, which no dialog is wide enough for.

  # Bulk creation used to be capped at 50. The dialog's stepper is the only way
  # in now and the mockup stops it at 20, which is already more sheets than a
  # course has weeks.
  BULK_RANGE = (2..20)

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_presentation, only: %i[new confirm_destroy]
  before_action :set_activity_group, only: %i[edit update destroy confirm_destroy]

  # GET /story_groups/:story_group_id/activity_groups
  def index
    @index = SheetIndex.new(@story_group)

    # Sheets created by the last request get the highlight animation, so a bulk
    # run of eight shows you which eight are new.
    @fresh_sheet_ids = Array(flash[:fresh_sheet_ids]).to_set(&:to_i)
  end

  # GET /story_groups/:story_group_id/activity_groups/new?template_id=:id
  #
  # The "Utwórz arkusz" dialog. Both modes live in one form: without
  # JavaScript you see the name field and the count together and pick with the
  # radio, and the stepper simply does not step.
  def new
    @template = @story_group.activity_group_templates.kept.find(params.expect(:template_id))
    @suggested_names = ActivityGroup.next_names_for_template(@template, BULK_RANGE.max)
  end

  # GET /story_groups/:story_group_id/activity_groups/:id/edit
  def edit; end

  # GET /story_groups/:story_group_id/activity_groups/:id/confirm_destroy
  def confirm_destroy
    @awards_count = awards_count_for(@activity_group)
  end

  def create
    template = @story_group.activity_group_templates.kept.find(create_params[:activity_group_template_id])
    sheets   = build_sheets(template)

    # An ordinary flash write, so it survives to the visit the stream triggers.
    flash[:fresh_sheet_ids] = sheets.map(&:id)
    redirect_outside_turbo_frame story_group_activity_groups_path(@story_group),
                                 notice: created_notice(sheets)
  rescue ActiveRecord::RecordInvalid => e
    redirect_outside_turbo_frame story_group_activity_groups_path(@story_group), alert: e.message
  end

  # PATCH/PUT /story_groups/:story_group_id/activity_groups/:id
  def update
    @activity_group.assign_attributes(activity_group_params)
    @activity_group.columns_modified_at = Time.current if columns_changed?

    if @activity_group.save(context: :settings)
      redirect_to story_group_activity_groups_path(@story_group),
                  notice: "Zapisano ustawienia arkusza #{@activity_group.name}.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/:story_group_id/activity_groups/:id
  #
  # Soft (DECISIONS.md:54). The sheet leaves the list; the currency it granted
  # stays with the students and stays in their history, which is what the
  # confirmation promises.
  def destroy
    name = @activity_group.name
    @activity_group.soft_delete!

    redirect_outside_turbo_frame story_group_activity_groups_path(@story_group),
                                 notice: "Usunięto arkusz #{name}. " \
                                         'Przyznane nagrody zostają w historii studentów.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_activity_group
    @activity_group = @story_group.activity_groups
                                  .kept
                                  .includes(activity_group_categories: :students_activity_group_categories)
                                  .find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def build_sheets(template)
    builder = ActivityGroupBuilder.new(story_group: @story_group, template: template)
    return builder.build_many(count: bulk_count) if create_params[:mode] == 'many'

    [builder.build(name: create_params[:name].presence || ActivityGroup.next_name_for_template(template))]
  end

  def bulk_count
    params[:count].to_i.clamp(BULK_RANGE.min, BULK_RANGE.max)
  end

  def created_notice(sheets)
    return "Utworzono: #{sheets.first.name}." if sheets.one?

    "Utworzono: #{sheets.first.name} – #{sheets.last.name}."
  end

  def columns_changed?
    @activity_group.activity_group_categories.any? do |category|
      category.new_record? || category.changed? || category.marked_for_destruction?
    end
  end

  def awards_count_for(activity_group)
    activity_group.activity_group_categories.sum(&:awards_count)
  end

  def create_params
    @create_params ||= params.expect(activity_group: %i[name activity_group_template_id mode])
  end

  def activity_group_params
    permitted = params.expect(
      activity_group: [
        :name,
        {
          activity_group_categories_attributes: [%i[
            id story_description didactic_description reward position hidden _destroy
          ]],
        },
      ],
    )

    reject_destroying_awarded_columns(permitted)
  end

  # DECISIONS.md:31 — a column that has already paid out can be hidden, never
  # removed. The editor offers hide instead of delete for those rows, but this
  # is the rule: destroying one would take its StudentsActivityGroupCategory
  # rows with it and leave the matching CurrencyTransactions pointing at
  # nothing, with the students keeping currency nobody can account for.
  def reject_destroying_awarded_columns(permitted)
    attributes = permitted[:activity_group_categories_attributes]
    return permitted if attributes.blank?

    # `expect` hands back an Array here, but fields_for posts a hash keyed by
    # row index; accept either rather than depending on which.
    entries = attributes.is_a?(Array) ? attributes : attributes.values

    entries.each do |attrs|
      next unless ActiveRecord::Type::Boolean.new.cast(attrs[:_destroy])
      next unless locked_category_ids.include?(attrs[:id].to_i)

      attrs.delete(:_destroy)
      attrs[:hidden] = true
    end

    permitted
  end

  def locked_category_ids
    @locked_category_ids ||= StudentsActivityGroupCategory
                             .where(activity_group_category_id: @activity_group.activity_group_category_ids)
                             .distinct
                             .pluck(:activity_group_category_id)
                             .to_set
  end
end
