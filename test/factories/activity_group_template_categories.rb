# frozen_string_literal: true

FactoryBot.define do
  factory :activity_group_template_category do
    association :activity_group_template
    story_description    { 'Story description' }
    didactic_description { 'Didactic description' }
    reward               { 10 }
    position             { 0 }
  end
end
