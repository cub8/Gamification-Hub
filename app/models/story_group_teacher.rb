# frozen_string_literal: true

class StoryGroupTeacher < ApplicationRecord
  belongs_to :user
  belongs_to :story_group

  delegate :full_name, :university_number, :email, to: :user
  scope :with_user, -> { includes(:user) }

  # Reachable by a double submit or a hand-built request — the add dialog shows
  # people already in the group wearing "Już w grupie", with no button. The
  # message is read straight out of errors[:user_id] by the dialog, so it is a
  # sentence rather than a fragment.
  validates :user_id, uniqueness: { scope: :story_group_id, message: 'Ta osoba jest już w grupie.' }
end
