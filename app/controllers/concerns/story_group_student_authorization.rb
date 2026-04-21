# frozen_string_literal: true

module StoryGroupStudentAuthorization

  def authorize_story_group_student_manage!
    authorize @student, :update?
  end
end
