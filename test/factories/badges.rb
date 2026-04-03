# frozen_string_literal: true

FactoryBot.define do
  factory :badge do
    association :story_group
    name { 'Achievement' }
    description { 'An achievement badge' }
    discount { 10 }
    icon { nil }
  end
end
