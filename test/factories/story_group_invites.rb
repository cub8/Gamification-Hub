# frozen_string_literal: true

FactoryBot.define do
  factory :story_group_invite do
    story_group { nil }
    code { 'MyString' }
    expires_at { '2026-04-26 19:49:04' }
    max_uses { 1 }
    uses { 1 }
  end
end
