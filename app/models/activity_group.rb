# frozen_string_literal: true

class ActivityGroup < ApplicationRecord
  belongs_to :story_group
  has_many :activity_group_categories, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :activity_group_categories, allow_destroy: true

  validates :name, presence: true, length: { maximum: 100 }
end
