# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.global_admin?
        scope.all
      elsif user.organization_admin?
        scope.where(id: user.organization.id)
      else
        scope.none
      end
    end
  end

  def show?
    user.global_admin? || user.organization_admin?
  end

  def new?
    user.global_admin?
  end

  def create?
    user.global_admin?
  end

  def edit?
    user.global_admin?
  end

  def update?
    user.global_admin?
  end

  def destroy?
    user.global_admin?
  end
end
