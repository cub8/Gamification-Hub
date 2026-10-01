# frozen_string_literal: true

class Item < ApplicationRecord
  include Iconable
  include SoftDeletable

  belongs_to :story_group
  has_many :currency_transactions, as: :transactionable

  belongs_to :unlock_rank, class_name: 'Rank', optional: true
  belongs_to :min_rank_for_discount, class_name: 'Rank', optional: true

  has_many :items_unlock_badges, dependent: :destroy
  has_many :unlock_badges, through: :items_unlock_badges, source: :badge

  has_many :items_min_badges_for_discounts, dependent: :destroy
  has_many :discount_badges, through: :items_min_badges_for_discounts, source: :badge

  has_many :students_items, dependent: :destroy

  has_icon_art :icon, glyphs: Glyphs::ITEM

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

  scope :by_price, -> { order(:price, :name, :id) }

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
