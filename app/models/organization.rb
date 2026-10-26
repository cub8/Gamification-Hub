# frozen_string_literal: true

class Organization < ApplicationRecord
  USOS_NAME = 'Uniwersytet im. Adama Mickiewicza w Poznaniu'

  has_many :users, dependent: :destroy

  validates :name, length: { maximum: 100 }, uniqueness: true
  validates :max_members, presence: true, numericality: { only_integer: true, greater_than: 0 }, unless: :usos?
  validates :max_members, absence: true, if: :usos?
  validate :max_members_not_below_members_count

  before_destroy :keep_usos_organization

  class << self
    def usos
      find_by(usos: true) || create!(usos: true, name: USOS_NAME)
    rescue ActiveRecord::RecordNotUnique
      find_by!(usos: true)
    end
  end

  def unlimited? = max_members.nil?

  def full?
    !unlimited? && users.count >= max_members
  end

  private

  def max_members_not_below_members_count
    return if new_record? || unlimited?

    members_count = users.count
    return if max_members >= members_count

    errors.add(:max_members, "can't be lower than the current number of members (#{members_count})")
  end

  def keep_usos_organization
    return unless usos?

    errors.add(:base, 'Organizacji powiązanej z USOS nie można usunąć.')
    throw :abort
  end
end
