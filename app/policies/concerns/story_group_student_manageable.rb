# frozen_string_literal: true

module StoryGroupStudentManageable
  private

  def can_manage_associated_story_group_student?
    student = extract_student
    can_manage_student?(student)
  end

  def can_manage_student?(student)
    StoryGroupStudentPolicy.new(user, student).update?
  end

  def extract_student
    unless scope.respond_to?(:proxy_association)
      raise ArgumentError, "Cannot extract student from #{scope.inspect}"
    end

    scope.proxy_association.owner
  end
end
