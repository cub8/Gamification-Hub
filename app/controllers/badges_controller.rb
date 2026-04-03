# frozen_string_literal: true

class BadgesController < ApplicationController
  before_action :set_story_group
  before_action :authorize
  before_action :set_badge, only: %i[show edit update destroy]

  # GET /story_groups/:story_group_id/badges
  def index
    @badges = @story_group.badges
  end

  # GET /story_groups/:story_group_id/badges/:id
  def show; end

  # GET /story_groups/:story_group_id/badges/new
  def new
    @badge = @story_group.badges.new
  end

  # GET /story_groups/:story_group_id/badges/:id/edit
  def edit; end

  # POST /story_groups/:story_group_id/badges
  def create
    @badge = @story_group.badges.build(badge_params)

    if @badge.save
      redirect_to story_group_badge_path(@story_group, @badge), notice: 'Badge was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /story_groups/:story_group_id/badges/:id
  def update
    if @badge.update(badge_params)
      redirect_to story_group_badge_path(@story_group, @badge), notice: 'Badge was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /story_groups/:story_group_id/badges/:id
  def destroy
    @badge.destroy
    redirect_to story_group_badges_path(@story_group), notice: 'Badge was successfully destroyed.'
  end

  private

  def set_story_group
    if @current_user.teacher?
      @story_group = @current_user.story_groups.find_by(id: params.expect(:story_group_id))
    elsif @current_user.organization_admin? || @current_user.global_admin?
      @story_group = StoryGroup.find(params.expect(:story_group_id))
    end
  end

  def set_badge
    @badge = @story_group.badges.find(params.expect(:id))
  end

  def badge_params
    params.expect(badge: %i[name description discount icon])
  end

  def authorize
    return if @current_user&.organization_admin? || @current_user&.global_admin? || @story_group

    redirect_to root_path, alert: 'Not found.'
  end
end
