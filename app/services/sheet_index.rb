# frozen_string_literal: true

# The "Arkusze ocen" index: every kept template of one group, each with the
# sheets stamped from it.
#
# The counts are the reason this is a service. The screen shows a category
# count and a reward ceiling per template, and an award count per sheet —
# three numbers that turn into three queries per row if a view asks the
# records for them. All of it is loaded here in four queries, whatever the
# group holds.
class SheetIndex
  Template = Struct.new(:record, :categories, :sheets) do
    def name           = record.base_name
    def category_count = categories.size
    # The ceiling in "do N marchewek na studenta za arkusz".
    def max_reward     = categories.sum { |category| category.reward.to_i }
    def any_sheets?    = sheets.any?
  end

  Sheet = Struct.new(:record, :awards_count) do
    def name              = record.name
    def graded?           = awards_count.positive?
    def columns_modified? = record.columns_modified?
  end

  def initialize(story_group)
    @story_group = story_group
  end

  attr_reader :story_group

  # Newest template first, and newest sheet first inside it — the mockup's
  # order, and the one that puts the sheet you are most likely grading at the
  # top of the screen.
  def templates
    @templates ||= template_records.map { |record| build_template(record) }
  end

  def any? = templates.any?

  private

  def template_records
    @template_records ||= story_group.activity_group_templates.kept.newest_first.to_a
  end

  def build_template(record)
    Template.new(record:     record,
                 categories: categories_by_template_id[record.id].to_a,
                 sheets:     sheets_for(record),)
  end

  def sheets_for(template)
    sheet_records.fetch(template.id, []).map do |record|
      Sheet.new(record: record, awards_count: awards_by_sheet_id[record.id].to_i)
    end
  end

  def categories_by_template_id
    @categories_by_template_id ||=
      ActivityGroupTemplateCategory.where(activity_group_template_id: template_records.map(&:id))
                                   .group_by(&:activity_group_template_id)
  end

  def sheet_records
    @sheet_records ||= story_group.activity_groups
                                  .kept
                                  .where(activity_group_template_id: template_records.map(&:id))
                                  .newest_first
                                  .group_by(&:activity_group_template_id)
  end

  # One grouped count over the join table, keyed back to the sheet through
  # its columns.
  def awards_by_sheet_id
    @awards_by_sheet_id ||=
      StudentsActivityGroupCategory
      .joins(:activity_group_category)
      .where(activity_group_categories: { activity_group_id: sheet_records.values.flatten.map(&:id) })
      .group('activity_group_categories.activity_group_id')
      .count
  end
end
