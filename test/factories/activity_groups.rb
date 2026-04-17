# frozen_string_literal: true

FactoryBot.define do
  factory :activity_group do
    association :story_group
    association :activity_group_template
    name { 'Lab 1' }
  end
end
