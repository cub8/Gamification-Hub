# frozen_string_literal: true

FactoryBot.define do
  factory :story_group do
    association :owner, factory: :user
    name { 'MyString' }
    description { 'MyText' }
    icon { nil }
    currency_name { 'MyString' }
    currency_icon { nil }
  end
end
