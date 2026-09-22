# frozen_string_literal: true

# The blueprint a sheet is stamped from — UI "Szablon arkusza". Editing one
# never reaches back into sheets that already exist (DECISIONS.md:30); it only
# changes what the next ActivityGroupBuilder run copies.
class ActivityGroupTemplate < ApplicationRecord
  belongs_to :story_group
  has_many :categories, class_name: 'ActivityGroupTemplateCategory', dependent: :destroy
  has_many :activity_groups, dependent: :destroy

  accepts_nested_attributes_for :categories, allow_destroy: true

  validates :base_name, presence: { message: 'Podaj nazwę szablonu.' }, length: { maximum: 100 }
  # Only on the editor form — see ActivityGroup for why.
  validate :at_least_one_category, on: :settings

  # Soft delete (DECISIONS.md:54). Deleting a template hides it from the index
  # and leaves every sheet made from it standing — those sheets own their own
  # copies of the columns, so nothing about them depends on the template still
  # being listed.
  scope :kept,    -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def deleted? = deleted_at.present?

  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  # The ceiling a sheet made from this template starts with.
  def max_reward = categories.sum { |category| category.reward.to_i }

  private

  def at_least_one_category
    return if categories.any? { |category| !category.marked_for_destruction? }

    errors.add(:base, 'Dodaj co najmniej jedną widoczną kategorię.')
  end
end
