# frozen_string_literal: true

class CurrencyAdjustmentsController < ApplicationController
  include StoryGroupAuthorization

  # A quick action, so a dialog (DECISIONS.md:26) — with the page fallback every
  # other dialog here has.

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_student
  before_action :set_presentation

  # GET /story_groups/:story_group_id/students/:student_id/currency_adjustment/new
  def new
    @form = CurrencyAdjustmentForm.for(@student)
  end

  # POST /story_groups/:story_group_id/students/:student_id/currency_adjustment
  def create
    @form = CurrencyAdjustmentForm.from_params(@student, params)

    if @form.save(granted_by_user: @current_user)
      redirect_outside_turbo_frame story_group_student_path(@story_group, @student, tab: 'hist'),
                                   notice: notice_for(@form)
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_student
    @student = @story_group.student_memberships.with_user.find(params.expect(:student_id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  # The mockup's own wording (30-student.js:68): the direction, the amount, and
  # what is left — the three things the teacher is about to want to check.
  def notice_for(form)
    verb = form.positive? ? 'Dodano' : 'Odjęto'

    "#{verb} #{form.value}. Saldo: #{@student.reload.current_currency}."
  end
end
