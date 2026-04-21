# frozen_string_literal: true

class StudentsBadgesController < ApplicationController
  include StoryGroupStudentAuthorization

  before_action :set_story_group
  before_action :set_student
  before_action :authorize_story_group_student_manage!
  before_action :set_badge, only: %i[destroy]

  def index
    @badges = policy_scope(@student.students_badges)
  end

  def new
    @badge = @student.students_badges.build
    @badges = Badge.where(story_group_id: @story_group.id)
  end

  def create
    @badge = @student.students_badges.build(badge_params)

    if @badge.save
      redirect_to story_group_student_badges_path(@story_group, @student),
                  notice: 'Badge was successfully given to student.'
    else
      @badges = Badge.where(story_group_id: @story_group.id)
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @badge.destroy

    redirect_to story_group_student_badges_path(@story_group, @student),
                notice: 'Badge was successfully taken from student.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_student
    @student = @story_group.student_memberships.find(params[:student_id])
  end

  def set_badge
    @badge = @student.students_badges.find(params[:id])
  end

  def badge_params
    params.expect(
      students_badge: %i[
        badge_id
      ],
    )
  end
end
