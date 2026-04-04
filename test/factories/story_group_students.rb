# frozen_string_literal: true

FactoryBot.define do
  factory :story_group_student do
    user_id { 1 }
    story_group_id { 1 }
    lives { 1 }
    current_currency { 1 }
    total_currency { 1 }
  end
end
