# frozen_string_literal: true

class ActivityGroupTemplateCategory < ApplicationRecord
  belongs_to :activity_group_template

  validates :reward, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
