# frozen_string_literal: true

FactoryBot.define do
  factory :story_group_student do
    association :user, :student
    association :story_group
    lives { 1 }
    current_currency { 1 }
    total_currency { 1 }
  end
end
