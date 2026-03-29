# frozen_string_literal: true

class RanksController < ApplicationController
  before_action :set_story_group
  before_action :authorize
  before_action :set_rank, only: %i[destroy]

  # POST /story_groups/:story_group_id/ranks
  def create
    @rank = @story_group.ranks.build(rank_params)

    if @rank.save
      redirect_to @story_group, notice: 'Rank was successfully created.'
    else
      redirect_to @story_group, alert: 'Error creating rank.'
    end
  end

  # DELETE /story_groups/:story_group_id/ranks/:id
  def destroy
    @rank.destroy!
    redirect_to @story_group, notice: 'Rank was successfully destroyed.', status: :see_other
  end

  private

  def set_story_group
    if @current_user&.teacher?
      @story_group = @current_user.story_groups.find_by(id: params.expect(:story_group_id))
    elsif @current_user&.organization_admin? || @current_user&.global_admin?
      @story_group = StoryGroup.find(params.expect(:story_group_id))
    end
  end

  def set_rank
    @rank = @story_group.ranks.find(params.expect(:id))
  end

  def rank_params
    params.expect(rank: %i[name description icon])
  end

  def authorize
    unless @current_user&.teacher? || @current_user&.organization_admin? || @current_user&.global_admin?
      return redirect_to root_path, alert: 'Not found.'
    end

    redirect_to root_path, alert: 'Not found.' unless @story_group
  end
end
