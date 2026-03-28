# frozen_string_literal: true

FactoryBot.define do
  factory :story_group do
<<<<<<< HEAD
=======
    association :owner, factory: :user
>>>>>>> origin/main
    name { 'MyString' }
    description { 'MyText' }
    icon { nil }
    currency_name { 'MyString' }
    currency_icon { nil }
  end
end
