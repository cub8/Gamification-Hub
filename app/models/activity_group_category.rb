# frozen_string_literal: true

class ActivityGroupCategory < ApplicationRecord
  belongs_to :activity_group

  default_scope { order(position: :asc) }

  validates :didactic_description, presence: true
  validates :reward, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
