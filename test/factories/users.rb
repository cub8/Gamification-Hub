# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    usos_id { 'MyString' }
    email { 'MyString' }
    full_name { 'MyString' }
    university_number { 'MyString' }
    university_name { 'MyString' }
    role { 1 }
    first_login { false }
  end
end
