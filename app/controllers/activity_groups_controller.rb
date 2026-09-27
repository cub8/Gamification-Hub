# frozen_string_literal: true

class ActivityGroupsController < ApplicationController
  include StoryGroupAuthorization

  BULK_RANGE = (2..20)

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_presentation, only: %i[new confirm_destroy]
  before_action :set_activity_group, only: %i[edit update destroy confirm_destroy]

  def index
    @index = SheetIndex.new(@story_group)
    @fresh_sheet_ids = Array(flash[:fresh_sheet_ids]).to_set(&:to_i)
  end

  def new
    @template = @story_group.activity_group_templates.kept.find(params.expect(:template_id))
    @suggested_names = ActivityGroup.next_names_for_template(@template, BULK_RANGE.max)
  end

  def edit; end

  def confirm_destroy
    @awards_count = awards_count_for(@activity_group)
  end

  def create
    template = @story_group.activity_group_templates.kept.find(create_params[:activity_group_template_id])
    sheets   = build_sheets(template)

    flash[:fresh_sheet_ids] = sheets.map(&:id)
    redirect_outside_turbo_frame story_group_activity_groups_path(@story_group),
                                 notice: created_notice(sheets)
  rescue ActiveRecord::RecordInvalid => e
    redirect_outside_turbo_frame story_group_activity_groups_path(@story_group), alert: e.message
  end

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

  def reject_destroying_awarded_columns(permitted)
    attributes = permitted[:activity_group_categories_attributes]
    return permitted if attributes.blank?

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
