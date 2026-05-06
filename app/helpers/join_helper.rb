# frozen_string_literal: true

module JoinHelper
  def user_in_group(user, story_group)
    story_group.student_memberships.intersect?(user.student_memberships)
  end
end
