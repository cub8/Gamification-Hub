# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:usos_id) { |n| "usos_#{n}" }
    sequence(:email) { |n| "user#{n}@st.amu.edu.pl" }
    full_name { 'Jan Nowak' }
    sequence(:university_number) { |n| "#{123456 + n}" }
    university_name { 'Example university' }
    first_login { false }
  end

  trait :student do
    role { 'student' }
  end

  trait :teacher do
    role { 'teacher' }
  end

  trait :organization_admin do
    role { 'organization_admin' }
  end

  trait :global_admin do
    role { 'global_admin' }
  end
end
