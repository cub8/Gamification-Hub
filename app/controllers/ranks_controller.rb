# frozen_string_literal: true

class RanksController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_read!, only: %i[index show]
  before_action :authorize_story_group_manage!, except: %i[index show]
  before_action :set_rank, only: %i[show edit update destroy]

  # GET /story_groups/:story_group_id/ranks
  def index
    @ranks = policy_scope(@story_group.ranks).order(:required_currency_value)
  end

  # GET /story_groups/:story_group_id/ranks/:id
  def show; end

  # GET /story_groups/:story_group_id/ranks/new
  def new
    @rank = @story_group.ranks.build
  end

  # GET /story_groups/:story_group_id/ranks/:id/edit
  def edit; end

  # POST /story_groups/:story_group_id/ranks
  def create
    @rank = @story_group.ranks.build(rank_params)

    if @rank.save
      redirect_to story_group_rank_path(@story_group, @rank), notice: 'Rank was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /story_groups/:story_group_id/ranks/:id
  def update
    if @rank.update(rank_params)
      redirect_to story_group_rank_path(@story_group, @rank), notice: 'Rank was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /story_groups/:story_group_id/ranks/:id
  def destroy
    @rank.destroy
    redirect_to story_group_ranks_path(@story_group), notice: 'Rank was successfully destroyed.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_rank
    @rank = @story_group.ranks.find(params.expect(:id))
  end

  def rank_params
    params.expect(
      rank: %i[
        name
        discount
        required_currency_value
        icon
      ],
    )
  end
end
