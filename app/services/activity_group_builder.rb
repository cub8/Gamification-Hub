# frozen_string_literal: true

# Stamps sheets out of a template. The columns are *copied*, not referenced —
# that copy is what makes a later template edit leave existing sheets alone
# (DECISIONS.md:30).
class ActivityGroupBuilder
  def initialize(story_group:, template:)
    @story_group = story_group
    @template    = template
  end

  def build(name:)
    build_all([name]).first
  end

  # The names come from ActivityGroup, the same call the create dialog uses to
  # draw its preview chips, so the two cannot disagree.
  def build_many(count:)
    build_all(ActivityGroup.next_names_for_template(@template, count))
  end

  private

  # One transaction for the whole run: a sheet that failed halfway used to
  # leave the ones before it behind, and the teacher had no way to tell how far
  # it got.
  def build_all(names)
    ActiveRecord::Base.transaction do
      names.map { |name| create_sheet(name) }
    end
  end

  # Categories are built before the save, not after it, because the sheet
  # validates that it has at least one visible column.
  def create_sheet(name)
    sheet = @story_group.activity_groups.new(name: name, activity_group_template: @template)

    @template.categories.order(:position).each_with_index do |category, index|
      sheet.activity_group_categories.new(
        story_description:    category.story_description,
        didactic_description: category.didactic_description,
        reward:               category.reward,
        position:             index,
        source_category:      category,
      )
    end

    sheet.save!
    sheet
  end
end
