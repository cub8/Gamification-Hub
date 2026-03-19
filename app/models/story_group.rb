# frozen_string_literal: true

class StoryGroup < ApplicationRecord
  has_one_attached :icon
  has_one_attached :currency_icon

  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id'

  validates :name, :currency_name, length: { maximum: 40 }
  validates :description, length: { maximum: 255 }
  validate :acceptable_icon

  # Te akceptowalne pliki obrazów raczej do zmiany, na razie tak przykładowo
  def acceptable_icon
    return unless icon.attached?

    acceptable_types = ['image/gif', 'image/jpeg', 'image/png']
    return if acceptable_types.include?(icon.content_type)

    errors.add(:icon, 'must be a GIF, JPG or PNG image')
  end

  validate :acceptable_currency_icon

  def acceptable_currency_icon
    return unless currency_icon.attached?

    acceptable_types = ['image/gif', 'image/jpeg', 'image/png']
    return if acceptable_types.include?(currency_icon.content_type)

    errors.add(:currency_icon, 'must be a GIF, JPG or PNG image')
  end
end
