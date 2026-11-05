# frozen_string_literal: true

class TeachersController < ApplicationController
  include StoryGroupAuthorization
  include TeacherInvitationDelivery

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :authorize_story_group_teachers!, only: %i[new create invite destroy confirm_destroy]
  before_action :set_presentation
  before_action :set_teacher, only: %i[destroy confirm_destroy]

  def index
    @list = TeacherList.new(story_group: @story_group,
                            memberships: policy_scope(@story_group.teacher_memberships),)
    @invitations = @story_group.teacher_invitations.newest_first.to_a if policy(@story_group).manage_teachers?
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
                                   notice: t('teachers.flash.added', name: @teacher.full_name)
    else
      set_pool
      render :new, status: :unprocessable_content
    end
  end

  def invite
    email  = params.dig(:teacher_invitation, :email)
    result = TeacherInviter.new(story_group: @story_group, inviter: @current_user, email: email).call

    if result.ok?
      deliver_teacher_invitation(result)
      redirect_outside_turbo_frame story_group_teachers_path(@story_group),
                                   notice: t("teachers.invite.flash.#{result.status}", email: result.email)
    else
      @teacher = @story_group.teacher_memberships.build
      @invite_email = result.email
      @invite_error = result.error
      set_pool
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    name = @teacher.full_name
    @teacher.destroy

    redirect_outside_turbo_frame story_group_teachers_path(@story_group),
                                 notice: t('teachers.flash.removed', name: name)
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
