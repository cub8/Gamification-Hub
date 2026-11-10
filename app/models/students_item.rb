# frozen_string_literal: true

class StudentsItem < ApplicationRecord
  belongs_to :story_group_student
  belongs_to :item

  validates :discount_applied, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: Discount::CAP_VALUE }
  validates :price_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
