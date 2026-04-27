# frozen_string_literal: true

class ItemsMinBadgesForDiscount < ApplicationRecord
  belongs_to :item
  belongs_to :badge
end
