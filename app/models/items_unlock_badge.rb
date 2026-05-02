# frozen_string_literal: true

class ItemsUnlockBadge < ApplicationRecord
  belongs_to :item
  belongs_to :badge
end
