# frozen_string_literal: true

class StudentsBadge < ApplicationRecord
  belongs_to :story_group_student
  belongs_to :badge

  delegate :story_group, to: :story_group_student
  delegate :name, :description, :discount, :icon, to: :badge
  scope :with_badge, -> { includes(:badge) }
end
