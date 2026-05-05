# frozen_string_literal: true

class StoryGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.organization_admin? || user.global_admin?
        scope.all.includes(:owner)
      elsif user.teacher?
        owner = scope.where(owner_id: user.id) # and also those to which they belong as teacher and student
        teaching = scope.where(id: user.teacher_story_groups.select(:id))
        enrolled = scope.where(id: user.student_story_groups.select(:id))

        owner.or(teaching)
             .or(enrolled)
             .distinct
             .includes(:owner)
      else
        scope.where(id: user.student_story_groups.select(:id))
             .distinct
             .includes(:owner)
      end
    end
  end

  def show?
    admin? || owner? || member?
  end

  def create?
    user.teacher? || admin?
  end

  def new?
    create?
  end

  def update?
    owner? || admin? || assistant?
  end

  def edit?
    update?
  end

  def destroy?
    owner? || admin?
  end

  def view_ranking?
    admin? || owner? || assistant? || (student? && record.ranking_enabled?)
  end

  def owner?
    record.owner_id == user.id
  end

  def student?
    record.students.include?(user)
  end

  private

  def admin?
    user.global_admin? || user.organization_admin?
  end

  # For teachers and students belonging
  # to the story group
  def member?
    assistant? || student?
  end

  def assistant?
    record.teachers.include?(user)
  end
end
