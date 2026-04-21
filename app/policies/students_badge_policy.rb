# frozen_string_literal: true

class StudentsBadgePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    include StoryGroupStudentManageable

    def resolve
      return scope if can_manage_associated_story_group_student?

      scope.none
    end
  end
end
