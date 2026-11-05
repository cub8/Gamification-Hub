# frozen_string_literal: true

FactoryBot.define do
  factory :teacher_invitation do
    association :story_group
    association :invited_by, factory: :user
    sequence(:email) { |n| "invited#{n}@example.com" }
  end
end
