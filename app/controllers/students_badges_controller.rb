# frozen_string_literal: true

class StudentsBadgesController < ApplicationController
  include StoryGroupAuthorization
  include RedesignLayout

  # Both screens are dialogs — awarding and revoking are quick actions on the
  # student sheet (DECISIONS.md:26) — each with the usual page fallback.
  layout -> { @in_modal ? false : 'redesign' }

  # The picker renders the badge art partial.
  helper BadgesHelper

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_student
  before_action :set_presentation
  before_action :set_students_badge, only: %i[confirm_destroy destroy]

  # GET /story_groups/:story_group_id/students/:student_id/badges/new
  def new
    @students_badge = @student.students_badges.build
    set_badges
  end

  # GET .../badges/:id/confirm_destroy
  def confirm_destroy; end

  # POST /story_groups/:story_group_id/students/:student_id/badges
  def create
    @students_badge = @student.students_badges.build(badge_params)

    if @students_badge.save
      redirect_outside_turbo_frame story_group_student_path(@story_group, @student),
                                   notice: "Przyznano odznakę „#{@students_badge.name}”."
    else
      set_badges
      render :new, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/:story_group_id/students/:student_id/badges/:id
  #
  # Only the award goes. The badge itself is untouched, and so is everything the
  # student bought while holding it.
  def destroy
    name = @students_badge.name
    @students_badge.destroy

    redirect_outside_turbo_frame story_group_student_path(@story_group, @student),
                                 notice: "Odebrano odznakę „#{name}”."
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_student
    @student = @story_group.student_memberships.with_user.find(params.expect(:student_id))
  end

  def set_students_badge
    @students_badge = @student.students_badges.with_badge.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  # `kept`: a withdrawn badge is off every picker. One a student already holds
  # stays on their deck, but it is no longer something to hand out.
  def set_badges
    @badges = @story_group.badges.kept.with_attached_icon.by_name.to_a
    @held   = @student.students_badges.pluck(:badge_id).to_set
  end

  def badge_params
    params.expect(students_badge: %i[badge_id])
  end
end
