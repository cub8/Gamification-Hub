# frozen_string_literal: true

class Badge < ApplicationRecord
  ACCEPTABLE_ICON_TYPES = ['image/gif', 'image/jpeg', 'image/png'].freeze

  has_one_attached :icon

  has_many :students_badges, dependent: :destroy

  belongs_to :story_group

  validates :name, presence: { message: 'Podaj nazwę odznaki.' },
                   length:   { maximum: 50 }

  validates :didactic_description, presence: { message: 'Napisz, jak zdobyć tę odznakę.' },
                                   length:   { maximum: 255 }

  validates :story_description, length: { maximum: 255 }

  validates :discount, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to:    100,
    message:                  'Zniżka musi mieścić się między 0 a 100%.',
  }

  validates :icon_glyph, inclusion: { in: Glyphs::BADGE, message: 'Nieznana grafika.' },
                         allow_nil: true

  validate :acceptable_icon
  validate :art_chosen

  scope :kept,    -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :by_name, -> { order(:name, :id) }

  def acceptable_icon
    return unless icon.attached?
    return if ACCEPTABLE_ICON_TYPES.include?(icon.content_type)

    errors.add(:icon, 'Grafika musi być plikiem GIF, JPG lub PNG.')
  end

  def art_chosen
    return if icon_glyph.present? || icon.attached?

    errors.add(:icon_glyph, 'Wybierz gotową grafikę albo wgraj własną.')
  end

  def deleted? = deleted_at.present?

  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  def art
    icon_glyph.presence || (icon.attached? ? :upload : nil)
  end

  def upload?
    art == :upload
  end

  def dependent_items
    Item.where(id: ItemsUnlockBadge.where(badge_id: id).select(:item_id))
        .or(Item.where(id: ItemsMinBadgesForDiscount.where(badge_id: id).select(:item_id)))
  end

  def unlocking_items
    Item.where(id: ItemsUnlockBadge.where(badge_id: id).select(:item_id))
  end
end
