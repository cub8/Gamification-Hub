# frozen_string_literal: true

class Item < ApplicationRecord
  belongs_to :story_group
  has_many :currency_transactions, as: :transactionable

  belongs_to :unlock_rank, class_name: 'Rank', optional: true
  belongs_to :min_rank_for_discount, class_name: 'Rank', optional: true

  has_many :items_unlock_badges, dependent: :destroy
  has_many :unlock_badges, through: :items_unlock_badges, source: :badge

  has_many :items_min_badges_for_discounts, dependent: :destroy
  has_many :discount_badges, through: :items_min_badges_for_discounts, source: :badge

  has_many :students_items, dependent: :destroy

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  has_one_attached :image
end
