# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    association :story_group
    name { 'Item' }
    can_buy_at_0_lives { false }
    price { 20 }
    story_description { 'Story Description' }
    didactic_description { 'Didactic description' }
  end
end
