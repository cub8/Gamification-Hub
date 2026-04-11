# frozen_string_literal: true

class StoryGroupTeacherPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    include StoryGroupManageable

    def resolve
      if admin?
        teacher_scope.all.includes(:user)
      elsif user.teacher?
        teacher_scope.joins(:story_group)
                     .where(story_groups: { owner_id: user.id })
                     .joins(:user)
                     .where(users: { university_name: user.university_name })
                     .distinct
                     .includes(:user)
      else
        scope.none
      end
    end

    private

    def admin?
      user.organization_admin? || user.global_admin?
    end

    def teacher_scope
      scope.joins(:user)
           .where(users: {
                    role: [
                      User.roles[:teacher],
                      User.roles[:organization_admin],
                      User.roles[:global_admin],
                    ],
                  })
           .distinct
    end
  end

  def index?
    (teacher? && owner?) || admin?
  end

  def create?
    !record.nil? || !record.user.nil? || (teacher? && record_teacher? && owner?) || (admin? && record_teacher?)
  end

  def destroy?
    (teacher? && owner?) || admin?
  end

  private

  def admin?
    user.organization_admin? || user.global_admin?
  end

  def teacher?
    user.teacher? || admin?
  end

  def record_teacher?
    record.user.teacher? || record.user.organization_admin? || record.user.global_admin?
  end

  def owner?
    record.story_group.owner_id == user.id
  end
end
