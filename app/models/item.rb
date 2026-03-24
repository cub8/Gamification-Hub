# frozen_string_literal: true

class Item < ApplicationRecord
  belongs_to :story_group

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
