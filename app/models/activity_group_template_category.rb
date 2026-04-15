# frozen_string_literal: true

class ActivityGroupTemplateCategory < ApplicationRecord
  default_scope { order(position: :asc) }

  belongs_to :activity_group_template

  validates :didactic_description, presence: true
  validates :reward, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
