FactoryBot.define do
  factory :story_group do
    owner_id { 1 }
    name { "MyString" }
    description { "MyText" }
    icon { nil }
    currency_name { "MyString" }
    currency_icon { nil }
  end
end
