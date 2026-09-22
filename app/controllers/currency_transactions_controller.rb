# frozen_string_literal: true

class CurrencyTransactionsController < ApplicationController
  before_action :set_story_group
  before_action :set_student

  # GET /story_groups/:story_group_id/students/:student_id/currency_transactions
  #
  # The student's own "Historia waluty", reached from the balance chip in the
  # header. The teacher reads the same ledger through the third tab of the
  # student sheet, from the same partial — this action serves one persona.
  def index
    skip_policy_scope

    @ledger = CurrencyLedger.new(student: @student)
    @kind   = ledger_kind
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  # `show?` is the one predicate both personas pass: the group's teachers, and
  # the student themselves. Authorising here rather than in the action so no
  # future action can forget it.
  def set_student
    @student = @story_group.student_memberships.with_user.find(params.expect(:student_id))
    authorize @student, :show?
  end

  def ledger_kind
    kinds = CurrencyLedger::KINDS.map(&:first).compact
    kinds.include?(params[:kind]) ? params[:kind] : nil
  end
end
