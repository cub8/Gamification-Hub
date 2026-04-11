# frozen_string_literal: true

class ActivityGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    include StoryGroupManageable

    def resolve
      return scope if can_manage_associated_story_group?

      scope.none
    end
  end
end
