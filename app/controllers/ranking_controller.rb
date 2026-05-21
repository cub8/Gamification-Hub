# frozen_string_literal: true

class RankingController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!, only: :change_status

  def show
    authorize @story_group, :view_ranking?
    skip_policy_scope
    @students = @story_group.student_memberships.with_user.order(total_currency: :desc)

    ranks = @story_group.ranks.order(required_currency_value: :desc).to_a
    @student_ranks = @students.to_h do |student|
      rank = ranks.bsearch { |r| r.required_currency_value <= student.total_currency }
      [student.id, rank]
    end
  end

  def change_status
    enabled = params[:ranking_enabled] == 'true'
    @story_group.update!(ranking_enabled: enabled)
    notice = enabled ? 'Ranking enabled.' : 'Ranking disabled.'
    redirect_to story_group_ranking_path(@story_group), notice: notice
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params[:story_group_id])
  end
end
