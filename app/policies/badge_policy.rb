# frozen_string_literal: true

class BadgePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    include StoryGroupManageable

    def resolve
      return scope if can_manage_associated_story_group?

      if user
        return scope
      end

      scope.none
    end
  end
end
