# frozen_string_literal: true

class CurrencyTransaction < ApplicationRecord
  belongs_to :student,         class_name: 'StoryGroupStudent'
  belongs_to :granted_by_user, class_name: 'User', optional: true
  belongs_to :transactionable, polymorphic: true

  enum :kind, { reward: 0, adjustment: 1, purchase: 2 }

  validates :amount, presence: true
  validates :kind,   presence: true
end
