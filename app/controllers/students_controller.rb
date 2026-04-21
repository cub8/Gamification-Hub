# frozen_string_literal: true

class StudentsController < ApplicationController
  before_action :set_story_group
  before_action :set_student, only: %i[show edit update destroy grant_life take_life]

  def index
    @students = policy_scope(@story_group.student_memberships)
  end

  def show
    authorize @student
  end

  def new
    @student = @story_group.student_memberships.build
    set_students_for_select

    authorize @student
  end

  def edit
    authorize @student
  end

  def create
    @student = @story_group.student_memberships.build(create_student_params)
    authorize @student

    if @student.save
      redirect_to story_group_students_path(@story_group),
                  notice: 'Student was successfully added to story group.'
    else
      set_students_for_select
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @student

    if @student.update(update_student_params)
      redirect_to story_group_students_path(@story_group),
                  notice: 'Student was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def take_life
    authorize @student

    if @student.lives > 0 && @student.update(lives: @student.lives - 1)
      redirect_to story_group_student_path(@story_group, @student),
                  notice: 'Student\'s life was successfully taken away', status: :see_other
    else
      render :show, status: :unprocessable_content
    end
  end

  def grant_life
    authorize @student

    if @student.update(lives: @student.lives + 1)
      redirect_to story_group_student_path(@story_group, @student),
                  notice: 'Student was succesfully granted life', status: :see_other
    else
      render :show, status: :unprocessable_content
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

  def set_students_for_select
    @students =
      if @current_user.global_admin?
        User.all
      else
        User.where(university_name: @current_user.university_name)
      end
  end

  def create_student_params
    params.expect(
      story_group_student: %i[
        user_id
      ],
    )
  end

  def update_student_params
    params.expect(
      story_group_student: %i[
        lives
      ],
    )
  end
end
