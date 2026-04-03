# frozen_string_literal: true

class ActivityGroupCategory < ApplicationRecord
  belongs_to :activity_group

  validates :reward, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
