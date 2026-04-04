# frozen_string_literal: true

class StoryGroupTeacher < ApplicationRecord
  belongs_to :user, foreign_key: 'user_id'
  belongs_to :story_group, foreign_key: 'story_group_id'

  validates :user_id, presence: true
  validates :story_group_id, presence: true
  validates :user_id, uniqueness: { scope: :story_group_id }
end
