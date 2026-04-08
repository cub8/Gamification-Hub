# frozen_string_literal: true

class ActivityGroup < ApplicationRecord
  belongs_to :story_group
  has_many :activity_group_categories, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :activity_group_categories, allow_destroy: true

  validates :name, presence: true, length: { maximum: 100 }

  def self.next_name_for(story_group)
    last = story_group.activity_groups.last
    return (story_group.activity_groups.count + 1).to_s unless last

    parts = last.name.to_s.split(' ')
    number = Integer(parts.last)
    "#{parts[0..-2].join(' ')} #{number + 1}"
  rescue ArgumentError, TypeError
    "#{last.name} #{story_group.activity_groups.count + 1}"
  end

  def self.next_number_for_base(story_group, base_name)
    all = story_group.activity_groups.to_a
    matching = all.select { |g| g.name.to_s.split(' ')[0..-2].join(' ') == base_name }

    last = matching.last
    return all.count + 1 unless last

    Integer(last.name.to_s.split(' ').last) + 1
  rescue ArgumentError, TypeError
    all.count + 1
  end
end
