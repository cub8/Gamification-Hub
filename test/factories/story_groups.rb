# frozen_string_literal: true

FactoryBot.define do
  factory :story_group do
    association :owner, :teacher, factory: :user
    sequence(:name) { |n| "Group #{n}" }
    description { 'A story group for tests' }
    icon { nil }
    currency_name { 'Coins' }
    currency_icon { nil }
    default_lives { 3 }
  end
end
