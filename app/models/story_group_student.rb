# frozen_string_literal: true

class StoryGroupStudent < ApplicationRecord
  belongs_to :user
  belongs_to :story_group

  has_many :students_badges

  delegate :full_name, :university_number, :email, to: :user
  scope :with_user, -> { includes(:user) }

  before_validation :set_default_lives_from_group, on: :create

  validates :user_id, uniqueness: { scope: :story_group_id }
  validates :lives, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def set_default_lives_from_group
    return unless lives.nil? && story_group.present?

    self.lives = story_group.default_lives

  end
end
