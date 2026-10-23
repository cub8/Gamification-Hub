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
    user.global_admin? || own_organization_admin?
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

  def new_admin?
    user.global_admin?
  end

  def add_admin?
    user.global_admin?
  end

  def new_user?
    manage_users?
  end

  def add_user?
    manage_users?
  end

  def manage_users?
    user.global_admin? || own_organization_admin?
  end

  private

  def own_organization_admin?
    user.organization_admin? && user.organization_id == record.id
  end
end
