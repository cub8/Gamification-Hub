# frozen_string_literal: true

class StudentsController < ApplicationController

  before_action :set_story_group
  before_action :set_student, only: %i[destroy]

  def index
    @story_group_students = policy_scope(@story_group.story_group_students)
    @story_group_student = StoryGroupStudent.new
    @story_group_student.story_group_id = @story_group.id

    authorize @story_group_student
  end

  def create
    @story_group_student = StoryGroupStudent.new(student_params)
    @story_group_student.story_group_id = @story_group.id

    authorize @story_group_student

    if @story_group_student.save
      redirect_to story_group_students_path(@story_group),
                  notice: 'Student was successfully added to story group.'
    else
      index
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    authorize @story_group_student

    @story_group_student.destroy

    redirect_to story_group_students_path(@story_group),
                notice: 'Student was successfully removed from story group.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_student
    @story_group_student = @story_group.story_group_students.find(params[:id])
  end

  def student_params
    params.expect(
      story_group_student: %i[
        user_id
      ],
    )
  end
end
