# frozen_string_literal: true

class TeachersController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :authorize_story_group_teachers!, only: %i[new create destroy confirm_destroy]
  before_action :set_presentation
  before_action :set_teacher, only: %i[destroy confirm_destroy]

  def index
    @list = TeacherList.new(story_group: @story_group,
                            memberships: policy_scope(@story_group.teacher_memberships),)
  end

  def new
    @teacher = @story_group.teacher_memberships.build
    set_pool
  end

  def confirm_destroy; end

  def create
    @teacher = @story_group.teacher_memberships.build(teacher_params)

    if @teacher.save
      redirect_outside_turbo_frame story_group_teachers_path(@story_group),
                                   notice: "Dodano: #{@teacher.full_name}."
    else
      set_pool
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    name = @teacher.full_name
    @teacher.destroy

    redirect_outside_turbo_frame story_group_teachers_path(@story_group),
                                 notice: "Usunięto z grupy: #{name}."
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_teacher
    @teacher = @story_group.teacher_memberships.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def set_pool
    @pool = TeacherPool.new(story_group: @story_group, viewer: @current_user)
  end

  def teacher_params
    params.expect(
      story_group_teacher: %i[
        user_id
      ],
    )
  end
end
