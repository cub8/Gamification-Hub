# frozen_string_literal: true

class RankingController < ApplicationController
  before_action :set_story_group

  def show
    authorize @story_group
    skip_policy_scope
    @students = @story_group.student_memberships.with_user.order(total_currency: :desc)
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end
end
