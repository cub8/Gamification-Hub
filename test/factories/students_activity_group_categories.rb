# frozen_string_literal: true

FactoryBot.define do
  factory :students_activity_group_category do
    association :student, factory: :story_group_student
    association :activity_group_category
  end
end
