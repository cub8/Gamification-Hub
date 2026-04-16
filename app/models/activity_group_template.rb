# frozen_string_literal: true

class ActivityGroupTemplate < ApplicationRecord
  belongs_to :story_group
  has_many :categories, class_name: 'ActivityGroupTemplateCategory', dependent: :destroy
  has_many :activity_groups, dependent: :destroy

  accepts_nested_attributes_for :categories,
                                allow_destroy: true

  validates :base_name, presence: true, length: { maximum: 100 }
end
