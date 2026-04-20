# frozen_string_literal: true

class StoryGroupStudent < ApplicationRecord
  belongs_to :user
  belongs_to :story_group

  has_many :student_activity_group_categories, foreign_key: :student_id, dependent: :destroy

  delegate :full_name, :university_number, :email, to: :user
  scope :with_user, -> { includes(:user) }

  validates :user_id, uniqueness: { scope: :story_group_id }
end
