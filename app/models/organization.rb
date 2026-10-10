# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :users, dependent: :destroy

  validates :name, length: { maximum: 100 }, uniqueness: true
  validates :max_members, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :max_members_not_below_members_count

  def full?
    max_members.present? && users.count >= max_members
  end

  private

  def max_members_not_below_members_count
    return if new_record? || max_members.blank?

    members_count = users.count
    return if max_members >= members_count

    errors.add(:max_members, "can't be lower than the current number of members (#{members_count})")
  end
end
