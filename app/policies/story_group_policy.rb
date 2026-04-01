# frozen_string_literal: true

class StoryGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.organization_admin? || user.global_admin?
        scope.all
      elsif user.teacher?
        scope.where(owner_id: user.id) # and also those to which they belong as teacher and student
      else
        scope.none
      end
    end
  end

  def show?
    return true if admin? || owner?

    member?
  end

  def create?
    user.teacher? || admin?
  end

  def new?
    create?
  end

  def update?
    owner? || admin?
  end

  def edit?
    update?
  end

  def destroy?
    update?
  end

  private

  def admin?
    user.global_admin? || user.organization_admin?
  end

  def owner?
    record.owner_id == user.id
  end

  # For teachers and students belonging
  # to the story group
  def member?
    false
  end
end
