# frozen_string_literal: true

class StudentsController < ApplicationController

  before_action :set_story_group
  before_action :set_student, only: %i[destroy]

  def index
    @students = policy_scope(@story_group.student_memberships)
  end

  def new
    @student = @story_group.student_memberships.build

    @students = if @current_user.global_admin?
                  User.all
                else
                  User.where(university_name: @current_user.university_name)
                end

    authorize @student
  end

  def create
    @student = @story_group.student_memberships.build(student_params)

    authorize @student

    if @student.save
      redirect_to story_group_students_path(@story_group),
                  notice: 'Student was successfully added to story group.'
    else
      @students = if @current_user.global_admin?
                    User.all
                  else
                    User.where(university_name: @current_user.university_name)
                  end
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    authorize @student

    @student.destroy

    redirect_to story_group_students_path(@story_group),
                notice: 'Student was successfully removed from story group.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_student
    @student = @story_group.student_memberships.find(params[:id])
  end

  def student_params
    params.expect(
      story_group_student: %i[
        user_id
      ],
    )
  end
end
