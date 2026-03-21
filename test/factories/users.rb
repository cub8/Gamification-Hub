# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    usos_id { '123456' }
    email { 'jan.nowak@st.amu.edu.pl' }
    full_name { 'Jan Nowak' }
    university_number { '123456' }
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
