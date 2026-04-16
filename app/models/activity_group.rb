# frozen_string_literal: true

class ActivityGroup < ApplicationRecord
  belongs_to :story_group
  belongs_to :activity_group_template

  has_many :activity_group_categories, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :activity_group_categories, allow_destroy: true

  validates :name, presence: true, length: { maximum: 100 }

  class << self
    def next_name_for_template(template)
      "#{template.base_name} #{next_number_for_base(template)}"
    end

    def next_number_for_base(template)
      matching = template.activity_groups
                         .where('name ~* ?', "^#{Regexp.escape(template.base_name)} [0-9]+$")
                         .order(:id)

      last = matching.last
      return template.activity_groups.count + 1 unless last

      Integer(last.name.to_s.split(' ').last) + 1
    rescue ArgumentError, TypeError
      template.activity_groups.count + 1
    end
  end
end
