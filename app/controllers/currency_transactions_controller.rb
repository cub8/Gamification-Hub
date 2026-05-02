# frozen_string_literal: true

class CurrencyTransactionsController < ApplicationController
  before_action :set_story_group
  before_action :set_student

  def index
    skip_policy_scope
    @transactions = @student.currency_transactions
                            .includes(:transactionable, :granted_by_user)
                            .order(created_at: :desc)
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end

  def set_student
    @student = @story_group.student_memberships.find(params[:student_id])
    authorize @student, :show?
  end
end
