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

    StoryGroupStudentPolicy.new(user, target_student).show?
  end

  def show?
    index?
  end
end
