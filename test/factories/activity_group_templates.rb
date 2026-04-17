# frozen_string_literal: true

FactoryBot.define do
  factory :activity_group_template do
    association :story_group
    base_name { 'Lab' }
  end
end
