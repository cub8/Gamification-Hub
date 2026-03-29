# frozen_string_literal: true

class BadgesController < ApplicationController
  before_action :set_story_group
  before_action :authorize
  before_action :set_badge, only: %i[destroy]

  # POST /story_groups/:story_group_id/badges
  def create
    @badge = @story_group.badges.build(badge_params)

    if @badge.save
      redirect_to @story_group, notice: 'Badge was successfully created.'
    else
      redirect_to @story_group, alert: 'Error creating badge.'
    end
  end

  # DELETE /story_groups/:story_group_id/badges/:id
  def destroy
    @badge.destroy!
    redirect_to @story_group, notice: 'Badge was successfully destroyed.', status: :see_other
  end

  private

  def set_story_group
    if @current_user&.teacher?
      @story_group = @current_user.story_groups.find_by(id: params.expect(:story_group_id))
    elsif @current_user&.organization_admin? || @current_user&.global_admin?
      @story_group = StoryGroup.find(params.expect(:story_group_id))
    end
  end

  def set_badge
    @badge = @story_group.badges.find(params.expect(:id))
  end

  def badge_params
    params.expect(badge: %i[name description icon])
  end

  def authorize
    unless @current_user&.teacher? || @current_user&.organization_admin? || @current_user&.global_admin?
      return redirect_to root_path, alert: 'Not found.'
    end

    redirect_to root_path, alert: 'Not found.' unless @story_group
  end
end
