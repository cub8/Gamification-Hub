# frozen_string_literal: true

# One column of one sheet's grading table. Copied from a template category at
# sheet creation and owned by the sheet from then on.
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

  # `size`, not `count`: the editor and the grading table both preload the
  # association, and every row asks.
  def awards_count = students_activity_group_categories.size

  # A column that has paid out can be hidden but never removed
  # (DECISIONS.md:31) — the awards, and the currency behind them, hang off it.
  def locked? = awards_count.positive?

  # No template column behind it means it was added here, in sheet settings.
  def sheet_only? = source_category_id.nil?
end
