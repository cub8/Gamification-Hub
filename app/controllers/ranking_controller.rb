# frozen_string_literal: true

class RankingController < ApplicationController
  before_action :set_story_group

  def show
    authorize @story_group, :view_ranking?
    skip_policy_scope
    @students = @story_group.student_memberships.with_user.order(total_currency: :desc)
  end

  def enable
    authorize @story_group, :update?
    @story_group.update!(ranking_enabled: true)
    redirect_to story_group_ranking_path(@story_group), notice: 'Ranking enabled.'
  end

  def disable
    authorize @story_group, :update?
    @story_group.update!(ranking_enabled: false)
    redirect_to story_group_ranking_path(@story_group), notice: 'Ranking disabled.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end
end
