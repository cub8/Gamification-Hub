# frozen_string_literal: true

class ActivityGroupCategory < ApplicationRecord
  belongs_to :activity_group
  has_many :students_activity_group_categories, foreign_key: :activity_group_category_id, dependent: :destroy
  has_many :currency_transactions, as: :transactionable

  default_scope { order(position: :asc) }

  validates :didactic_description, presence: true
  validates :reward, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
