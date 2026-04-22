# frozen_string_literal: true

class StudentsBadgePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    include StoryGroupStudentManageable

    def resolve
      return scope if can_manage_associated_story_group_student?

      if user.student?
        return  scope.joins(story_group_student: :user)
                     .where(users: { id: user.id })
                     .distinct
                     .includes(story_group_student: :user)
      end

      scope.none
    end
  end
end
