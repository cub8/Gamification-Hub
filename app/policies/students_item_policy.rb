# frozen_string_literal: true

class StudentsItemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    include StoryGroupStudentManageable

    def resolve
      return scope if can_manage_associated_story_group_student?

      scope.joins(story_group_student: :user)
           .where(users: { id: user.id })
           .distinct
           .includes(story_group_student: :user)
    end
  end

  def index?
    target_student = record.respond_to?(:story_group_student) ? record.story_group_student : record

    user.teacher? || target_student.story_group.owner_id == user.id || target_student.user_id == user.id
  end

  def show?
    index?
  end
end
