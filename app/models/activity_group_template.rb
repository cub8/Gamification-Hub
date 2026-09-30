# frozen_string_literal: true

class ActivityGroupTemplate < ApplicationRecord
  include SoftDeletable

  belongs_to :story_group
  has_many :categories, class_name: 'ActivityGroupTemplateCategory', dependent: :destroy
  has_many :activity_groups, dependent: :destroy

  accepts_nested_attributes_for :categories, allow_destroy: true

  validates :base_name, presence: { message: 'Podaj nazwę szablonu.' }, length: { maximum: 100 }
  validate :at_least_one_category, on: :settings

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def max_reward = categories.sum { |category| category.reward.to_i }

  private

  def at_least_one_category
    return if categories.any? { |category| !category.marked_for_destruction? }

    errors.add(:base, 'Dodaj co najmniej jedną widoczną kategorię.')
  end
end
