# frozen_string_literal: true

FactoryBot.define do
  factory :story_group_invite do
    association :story_group, factory: :story_group
    code { SecureRandom.base64(8) }
    expires_at { 24.hours.from_now }
    max_uses { 10 }
    uses { 0 }
  end
end
