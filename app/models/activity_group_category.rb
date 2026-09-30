# frozen_string_literal: true

class ActivityGroupCategory < ApplicationRecord
  include RewardCategory

  belongs_to :activity_group
  belongs_to :source_category, class_name: 'ActivityGroupTemplateCategory', optional: true
  has_many :students_activity_group_categories, foreign_key: :activity_group_category_id, dependent: :destroy
  has_many :currency_transactions, as: :transactionable

  scope :visible, -> { where(hidden: false) }

  def awards_count = students_activity_group_categories.size

  def locked? = awards_count.positive?

  def sheet_only? = source_category_id.nil?
end
