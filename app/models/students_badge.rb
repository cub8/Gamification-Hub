# frozen_string_literal: true

class StudentsBadge < ApplicationRecord
  belongs_to :story_group_student
  belongs_to :badge

  delegate :story_group, to: :story_group_student
  delegate :name, :story_description, :didactic_description, :discount, :icon, to: :badge
  scope :with_badge, -> { includes(:badge) }

  validates :badge_id, uniqueness: { scope: :story_group_student_id }
end
