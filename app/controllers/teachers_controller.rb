# frozen_string_literal: true

class TeachersController < ApplicationController
  include StoryGroupAuthorization
  include RedesignLayout

  # Inside the dialog only the frame is used, and the redesign layout already
  # carries a <turbo-frame id="modal"> of its own. Rendering it too would put
  # two frames with the same id in one response and let Turbo pick whichever
  # came first.
  layout -> { @in_modal ? false : 'redesign' }

  before_action :set_story_group
  # Reaching the screen is "do you help run this group"; changing who is on it
  # is the owner's alone. The list itself stays readable to a supporting
  # teacher — knowing who else is here is not a privilege.
  before_action :authorize_story_group_manage!
  before_action :authorize_story_group_teachers!, only: %i[new create destroy confirm_destroy]
  before_action :set_presentation
  before_action :set_teacher, only: %i[destroy confirm_destroy]

  def index
    @list = Redesign::TeacherList.new(story_group: @story_group,
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
      # Named, like every other confirmation in the redesign — and the mockup's
      # own wording (30-rk.js `doAddT`).
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

    # Submitted from inside the confirmation dialog, so it has to break out of
    # the frame the same way create does.
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
    @pool = Redesign::TeacherPool.new(story_group: @story_group, viewer: @current_user)
  end

  def teacher_params
    params.expect(
      story_group_teacher: %i[
        user_id
      ],
    )
  end
end
