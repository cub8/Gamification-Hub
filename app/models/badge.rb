# frozen_string_literal: true

class Badge < ApplicationRecord
  include Iconable
  include SoftDeletable

  has_many :students_badges, dependent: :destroy

  belongs_to :story_group

  has_icon_art :icon, glyphs: Glyphs::BADGE

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

  scope :by_name, -> { order(:name, :id) }

  def dependent_items
    Item.where(id: ItemsUnlockBadge.where(badge_id: id).select(:item_id))
        .or(Item.where(id: ItemsMinBadgesForDiscount.where(badge_id: id).select(:item_id)))
  end

  def unlocking_items
    Item.where(id: ItemsUnlockBadge.where(badge_id: id).select(:item_id))
  end
end
