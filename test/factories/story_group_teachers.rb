# frozen_string_literal: true

FactoryBot.define do
  factory :story_group_teacher do
    association :user, factory: :user
    association :story_group, factory: :story_group
  end
end
