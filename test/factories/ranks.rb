# frozen_string_literal: true

FactoryBot.define do
  factory :rank do
    association :story_group
    name { 'Gold' }
    description { 'A gold rank' }
    icon { nil }
  end
end