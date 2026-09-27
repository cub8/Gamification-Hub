# frozen_string_literal: true

class Item < ApplicationRecord
  has_one_attached :icon

  belongs_to :story_group
  has_many :currency_transactions, as: :transactionable

  belongs_to :unlock_rank, class_name: 'Rank', optional: true
  belongs_to :min_rank_for_discount, class_name: 'Rank', optional: true

  has_many :items_unlock_badges, dependent: :destroy
  has_many :unlock_badges, through: :items_unlock_badges, source: :badge

  has_many :items_min_badges_for_discounts, dependent: :destroy
  has_many :discount_badges, through: :items_min_badges_for_discounts, source: :badge

  has_many :students_items, dependent: :destroy

  ACCEPTABLE_ICON_TYPES = ['image/gif', 'image/jpeg', 'image/png'].freeze

  validates :name, presence: { message: 'Podaj nazwę przedmiotu.' },
                   length:   { maximum: 50 }

  validates :didactic_description, presence: { message: 'Napisz, co przedmiot daje studentowi.' },
                                   length:   { maximum: 255 }

  validates :story_description, length: { maximum: 255 }

  validates :price, numericality: {
    only_integer:             true,
    greater_than_or_equal_to: 1,
    message:                  'Cena musi wynosić co najmniej 1.',
  }

  validates :icon_glyph, inclusion: { in: Glyphs::ITEM, message: 'Nieznana grafika.' },
                         allow_nil: true

  validate :acceptable_icon
  validate :art_chosen

  scope :kept,    -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :by_price, -> { order(:price, :name, :id) }

  def acceptable_icon
    return unless icon.attached?
    return if ACCEPTABLE_ICON_TYPES.include?(icon.content_type)

    errors.add(:icon, 'Grafika musi być plikiem GIF, JPG lub PNG.')
  end

  def art_chosen
    return if icon_glyph.present? || icon.attached?

    errors.add(:icon_glyph, 'Wybierz gotową grafikę albo wgraj własną.')
  end

  def art
    icon_glyph.presence || (icon.attached? ? :upload : nil)
  end

  def upload?
    art == :upload
  end

  def deleted?
    deleted_at.present?
  end

  def soft_delete!
    transaction do
      update_columns(deleted_at:               Time.current,
                     unlock_rank_id:           nil,
                     min_rank_for_discount_id: nil,)
      items_unlock_badges.delete_all
      items_min_badges_for_discounts.delete_all
    end
  end

  def discount_info_for(student)
    DiscountCalculatorService.new(student: student, item: self).calculate
  end

  def discounted_price_for(student)
    discount = discount_info_for(student)
    PriceCalculatorService.new(price: price, discount: discount).calculate
  end
end
