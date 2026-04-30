# frozen_string_literal: true

class StoryGroupStudentPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    include StoryGroupManageable

    def resolve
      if admin?
        scope.all.includes(:user)
      elsif user.teacher?
        owned = scope.joins(:story_group)
                     .where(story_groups: { owner_id: user.id })

        teaching = scope.joins(:story_group)
                        .where(story_groups: { id: user.teacher_story_groups.select(:id) })

        owned.or(teaching)
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
    story_group_teacher? || admin?
  end

  def show?
    story_group_teacher? || admin? || own_record?
  end

  def new?
    story_group_teacher? || admin?
  end

  def edit?
    story_group_teacher? || admin?
  end

  def create?
    story_group_teacher? || admin?
  end

  def update?
    story_group_teacher? || admin?
  end

  def destroy?
    story_group_teacher? || admin?
  end

  def update_lives?
    story_group_teacher? || admin?
  end

  private

  def admin?
    user.organization_admin? || user.global_admin?
  end

  def story_group_teacher?
    record.story_group.owner == user || user.teacher_story_groups.include?(record.story_group)
  end

  def own_record?
    record.user == user
  end

end
