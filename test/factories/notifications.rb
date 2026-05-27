# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :user
    association :story_group
    association :story_group_student
    association :item
    read_at { nil }
  end
end
