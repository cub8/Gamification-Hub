# frozen_string_literal: true

class TeachersController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_teacher, only: %i[destroy]

  def index
    @teachers = policy_scope(@story_group.teacher_memberships)
  end

  def new
    @teacher = @story_group.teacher_memberships.build

    @teachers = if @current_user.global_admin?
                  User.where(role: %i[teacher organization_admin global_admin])
                else
                  User.where(role:            %i[teacher organization_admin global_admin],
                             university_name: @current_user.university_name,)
                end
  end

  def create
    @teacher = @story_group.teacher_memberships.build(teacher_params)

    if @teacher.save
      redirect_to story_group_teachers_path(@story_group),
                  notice: 'Teacher was successfully added to story group.'
    else
      @teachers = if @current_user.global_admin?
                    User.where(role: %i[teacher organization_admin global_admin])
                  else
                    User.where(role:            %i[teacher organization_admin global_admin],
                               university_name: @current_user.university_name,)
                  end
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @teacher.destroy

    redirect_to story_group_teachers_path(@story_group),
                notice: 'Teacher was successfully removed from story group.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_teacher
    @teacher = @story_group.teacher_memberships.find(params[:id])
  end

  def teacher_params
    params.expect(
      story_group_teacher: %i[
        user_id
      ],
    )
  end
end
