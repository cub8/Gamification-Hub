# frozen_string_literal: true

FactoryBot.define do
  factory :students_item do
    association :story_group_student
    association :item
    price_paid { 10 }
    discount_applied { 0 }
  end
end
