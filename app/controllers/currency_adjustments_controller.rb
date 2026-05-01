# frozen_string_literal: true

class CurrencyAdjustmentsController < ApplicationController
  before_action :set_story_group
  before_action :set_student

  def new
    authorize @student, :adjust_currency?
  end

  def create
    authorize @student, :adjust_currency?

    amount = params.expect(currency_adjustment: :amount)[:amount].to_i
    CurrencyAdjusterService.new(student: @student, granted_by_user: @current_user).adjust(amount)

    redirect_to story_group_students_path(@story_group), notice: 'Currency adjusted.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_student
    @student = @story_group.student_memberships.find(params[:student_id])
  end
end
