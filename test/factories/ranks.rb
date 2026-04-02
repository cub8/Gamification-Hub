# frozen_string_literal: true

FactoryBot.define do
  factory :rank do
    association :story_group
    name { 'Gold' }
    discount { 10 }
    required_currency_value { 100 }
    icon { nil }
  end
end
