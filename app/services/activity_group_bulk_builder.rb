# frozen_string_literal: true

class ActivityGroupBulkBuilder
  def initialize(story_group:, template:, count: nil)
    @story_group = story_group
    @template    = template
    @count       = count
  end

  def build_one(name:)
    group = @story_group.activity_groups.create!(
      name:                    name,
      activity_group_template: @template,
    )
    copy_categories(group)
  end

  def build
    next_number = ActivityGroup.next_number_for_base(@template)

    @count.times do |i|
      name = "#{@template.base_name} #{next_number + i}"
      group = @story_group.activity_groups.create!(
        name:                    name,
        activity_group_template: @template,
      )
      copy_categories(group)
    end
  end

  private

  def copy_categories(group)
    @template.categories.order(:position).each_with_index do |cat, idx|
      group.activity_group_categories.create!(
        story_description:    cat.story_description,
        didactic_description: cat.didactic_description,
        reward:               cat.reward,
        position:             idx,
      )
    end
  end
end
