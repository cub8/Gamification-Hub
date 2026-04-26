# frozen_string_literal: true

class StudentsItem < ApplicationRecord
  belongs_to :story_group_student
  belongs_to :item

  validates :price_paid, presence: true
end
