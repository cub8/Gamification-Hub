# frozen_string_literal: true

class User < ApplicationRecord
  enum :role, {
    student:            1,
    teacher:            2,
    organization_admin: 3,
    global_admin:       4,
  }

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, length: { maximum: 255 }, uniqueness: true, allow_nil: true
  validates :usos_id, uniqueness: { scope: :university_name }, allow_nil: true
  validates :university_number, length: { maximum: 20 }
  validates :full_name, length: { maximum: 80 }
  validates :university_name, length: { maximum: 100 }

  has_many :story_groups, foreign_key: 'owner_id'
  validates_presence_of :email, :full_name, on: :account_setup

  def has_access_to_story_group?(story_group)
    story_group.owner == self || organization_admin? # || story_group.teachers.include?(self) # tutaj z
    # uwzględnieniem nauczycieli - bo w przyszłości mamy dopuszczać nauczycieli w ramach grup fabularnych
  end
end
