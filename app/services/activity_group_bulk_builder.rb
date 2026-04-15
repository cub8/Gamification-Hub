# frozen_string_literal: true

class ActivityGroupBulkBuilder
  def initialize(story_group:, template:, base_name:, count:)
    @story_group = story_group
    @template    = template
    @base_name   = base_name
    @count       = count
  end

  def build
    next_number = ActivityGroup.next_number_for_base(@story_group, @base_name)

    @count.times do |i|
      group = @story_group.activity_groups.create!(name: "#{@base_name} #{next_number + i}")
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
end
