# frozen_string_literal: true

class StoryGroupStudent < ApplicationRecord
  belongs_to :user
  belongs_to :story_group

  has_many :students_activity_group_categories, foreign_key: :student_id, dependent: :destroy
  has_many :students_badges, dependent: :destroy
  has_many :currency_transactions,              foreign_key: :student_id, dependent: :destroy
  has_many :students_items, dependent: :destroy

  delegate :full_name, :university_number, :email, to: :user
  scope :with_user, -> { includes(:user) }

  before_validation :set_default_lives_from_group, on: :create

  validates :user_id, uniqueness: { scope: :story_group_id }
  validates :lives, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def set_default_lives_from_group
    self.lives ||= story_group.default_lives
  end

  def update_lives(change)
    new_lives = lives + change

    update(lives: new_lives)
  end

  def rank
    story_group.ranks.where('required_currency_value <= ?', total_currency)
               .order(required_currency_value: :desc)
               .first
  end
end
