# frozen_string_literal: true

class ActivityGroupTemplate < ApplicationRecord
  belongs_to :story_group
  has_many :activity_group_template_categories, dependent: :destroy

  accepts_nested_attributes_for :activity_group_template_categories,
                                allow_destroy: true

  validates :base_name, presence: true, length: { maximum: 100 }
end
