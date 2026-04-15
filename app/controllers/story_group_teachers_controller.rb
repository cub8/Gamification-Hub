# frozen_string_literal: true

class StoryGroupTeachersController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_teacher, only: %i[destroy]

  def index
    @story_group_teachers = policy_scope(@story_group.story_group_teachers)
    @story_group_teacher = StoryGroupTeacher.new
    @story_group_teacher.story_group_id = @story_group.id

    authorize @story_group_teacher
  end

  def create
    @story_group_teacher = StoryGroupTeacher.new(teacher_params)
    @story_group_teacher.story_group_id = @story_group.id

    authorize @story_group_teacher

    if @story_group_teacher.save
      redirect_to story_group_story_group_teachers_path(@story_group),
                  notice: 'Teacher was successfully added to story group.'
    else
      index
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    authorize @story_group_teacher

    @story_group_teacher.destroy

    redirect_to story_group_story_group_teachers_path(@story_group),
                notice: 'Teacher was successfully removed from story group.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_teacher
    @story_group_teacher = @story_group.story_group_teachers.find(params[:id])
  end

  def teacher_params
    params.expect(
      story_group_teacher: %i[
        user_id
      ],
    )
  end
end
