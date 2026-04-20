# frozen_string_literal: true

FactoryBot.define do
  factory :students_badge do
    association :story_group_student
    association :badge
  end
end
