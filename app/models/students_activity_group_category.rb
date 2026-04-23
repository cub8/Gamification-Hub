# frozen_string_literal: true

class StudentsActivityGroupCategory < ApplicationRecord
  belongs_to :student, class_name: 'StoryGroupStudent'
  belongs_to :activity_group_category

  validates :student_id, uniqueness: { scope: :activity_group_category_id }
end
