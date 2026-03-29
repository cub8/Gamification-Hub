# frozen_string_literal: true

class Rank < ApplicationRecord
  has_one_attached :icon

  belongs_to :story_group

  validates :name, length: { maximum: 40 }
  validates :description, length: { maximum: 255 }
  validate :acceptable_icon
  
  def acceptable_icon
    return unless icon.attached?

    acceptable_types = ['image/gif', 'image/jpeg', 'image/png']
    return if acceptable_types.include?(icon.content_type)

    errors.add(:icon, 'must be a GIF, JPG or PNG image')
  end
end
