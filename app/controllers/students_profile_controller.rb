# frozen_string_literal: true

class StudentsProfileController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_read!
  before_action :set_student

  def index; end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_student
    @student = @story_group.student_memberships.find(params.expect(:student_id))
  end
end
