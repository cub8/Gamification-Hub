# frozen_string_literal: true

FactoryBot.define do
  factory :currency_transaction do
    association :student, factory: :story_group_student
    amount { 10 }
    kind   { :reward }
  end
end
