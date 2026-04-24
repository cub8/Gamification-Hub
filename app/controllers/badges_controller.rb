# frozen_string_literal: true

class BadgesController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_read!, only: %i[index show]
  before_action :authorize_story_group_manage!, except: %i[index show]
  before_action :set_badge, only: %i[show edit update destroy]

  # GET /story_groups/:story_group_id/badges
  def index
    @badges = policy_scope(@story_group.badges)
  end

  # GET /story_groups/:story_group_id/badges/:id
  def show; end

  # GET /story_groups/:story_group_id/badges/new
  def new
    @badge = @story_group.badges.build
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
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_badge
    @badge = @story_group.badges.find(params.expect(:id))
  end

  def badge_params
    params.expect(
      badge: %i[
        name
        story_description
        didactic_description
        discount
        icon
      ],
    )
  end
end
