# frozen_string_literal: true

FactoryBot.define do
  factory :badge do
    association :story_group
    name { 'Achievement' }
    story_description { 'An achievement badge' }
    didactic_description { 'A didactic description for the achievement badge' }
    discount { 10 }
    icon { nil }
  end
end
