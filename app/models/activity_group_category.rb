# frozen_string_literal: true

class ActivityGroupCategory < ApplicationRecord
  belongs_to :activity_group
  belongs_to :source_category, class_name: 'ActivityGroupTemplateCategory', optional: true
  has_many :students_activity_group_categories, foreign_key: :activity_group_category_id, dependent: :destroy
  has_many :currency_transactions, as: :transactionable

  default_scope { order(position: :asc) }

  scope :visible, -> { where(hidden: false) }

  validates :didactic_description, presence: { message: 'Podaj, za co jest nagroda.' }
  validates :reward,
            numericality: {
              only_integer:             true,
              greater_than_or_equal_to: 1,
              message:                  'Nagroda musi wynosić co najmniej 1.',
            }

  def awards_count = students_activity_group_categories.size

  def locked? = awards_count.positive?

  def sheet_only? = source_category_id.nil?
end
