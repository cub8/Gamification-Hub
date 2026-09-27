# frozen_string_literal: true

class ActivityGroupBuilder
  def initialize(story_group:, template:)
    @story_group = story_group
    @template    = template
  end

  def build(name:)
    build_all([name]).first
  end

  def build_many(count:)
    build_all(ActivityGroup.next_names_for_template(@template, count))
  end

  private

  def build_all(names)
    ActiveRecord::Base.transaction do
      names.map { |name| create_sheet(name) }
    end
  end

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
