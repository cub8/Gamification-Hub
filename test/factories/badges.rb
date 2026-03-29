# frozen_string_literal: true

FactoryBot.define do
  factory :badge do
    association :story_group
    name { 'Achievement' }
    description { 'An achievement badge' }
    icon { nil }
  end
end