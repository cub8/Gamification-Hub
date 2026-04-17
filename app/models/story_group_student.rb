# frozen_string_literal: true

class StoryGroupStudent < ApplicationRecord
  belongs_to :user
  belongs_to :story_group

  delegate :full_name, :university_number, :email, to: :user
  scope :with_user, -> { includes(:user) }

  validates :user_id, uniqueness: { scope: :story_group_id }
  validates :lives, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
