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

  def discount_info_for(student)
    rank_discount = 0
    student_rank = student.rank

    if student_rank.present? && (min_rank_for_discount.nil? ||
      student_rank.required_currency_value >= min_rank_for_discount.required_currency_value)

      rank_discount = student_rank.discount || 0
    end

    student_badges = student.students_badges.includes(:badge).map(&:badge)
    applicable_badges = student_badges & discount_badges
    badges_discount = applicable_badges.sum { |b| b.discount || 0 }

    total_discount = rank_discount + badges_discount

    {
      value:     [total_discount, 50].min,
      capped:    total_discount > 50,
      raw_total: total_discount,
    }
  end

  def discounted_price_for(student)
    discount = discount_info_for(student)[:value]
    return price if discount.zero?

    (price * (100 - discount) / 100.0).round
  end
end
