# frozen_string_literal: true

class StoryGroupStudentPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    include StoryGroupManageable

    def resolve
      if admin?
        scope.all.includes(:user)
      elsif user.teacher?
        scope.joins(:story_group)
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
  end

  def index?
    (teacher? && owner? && same_org?) || admin?
  end

  def create?
    !record.nil? || !record.user.nil? || (teacher? && owner? && same_org?) || admin?
  end

  def destroy?
    (teacher? && owner? && same_org?) || admin?
  end

  private

  def admin?
    user.organization_admin? || user.global_admin?
  end

  def teacher?
    user.teacher? || admin?
  end

  def owner?
    record.story_group.owner_id == user.id
  end

  def same_org?
    record.nil? ||
      record.user.nil? ||
      record.user.university_name.nil? ||
      user.university_name.nil? ||
      record.user.university_name == user.university_name
  end

end
