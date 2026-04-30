# frozen_string_literal: true

class CurrencyTransactionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  def index?
    story_group_teacher? || admin?
  end

  private

  def admin?
    user.organization_admin? || user.global_admin?
  end

  def story_group_teacher?
    record.story_group.owner == user || user.teacher_story_groups.include?(record.story_group)
  end
end
