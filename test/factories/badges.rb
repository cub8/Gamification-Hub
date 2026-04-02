# frozen_string_literal: true

FactoryBot.define do
  factory :badge do
    association :story_group
    name { 'Achievement' }
    description { 'An achievement badge' }
    discount { 10 }
    required_currency_value { 100 }
    icon { nil }
  end
end
