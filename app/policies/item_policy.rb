# frozen_string_literal: true

class ItemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user_can_manage_story_group?

      scope
    end

    private

    def user_can_manage_story_group?
      story_group = scope.proxy_association.owner
      StoryGroupPolicy.new(user, story_group).update?
    end
  end
end
