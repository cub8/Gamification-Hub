# frozen_string_literal: true

class StudentsController < ApplicationController
  before_action :set_story_group
  before_action :set_student, only: %i[show edit update destroy update_lives]

  def index
    @students = policy_scope(@story_group.student_memberships)
  end

  def show
    authorize @student
    @badges = policy_scope(@student.students_badges)
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

  def update_lives
    authorize @student

    change = params[:change].to_i

    if @student.update_lives(change)
      redirect_to story_group_students_path(@story_group),
                  notice: 'Successfully updated student\'s lives'
    else
      @failed_student_id = @student.id
      @students = policy_scope(@story_group.student_memberships)
      render :index, status: :unprocessable_content
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
