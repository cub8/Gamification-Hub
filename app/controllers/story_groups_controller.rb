# frozen_string_literal: true

class StoryGroupsController < ApplicationController
  before_action :set_story_group, only: %i[show edit update destroy]

  # GET /story_groups
  def index
    @story_groups = StoryGroup.all
  end

  # GET /story_groups/1
  def show; end

  # GET /story_groups/new
  def new
    @story_group = StoryGroup.new
  end

  # GET /story_groups/1/edit
  def edit; end

  # POST /story_groups
  def create
    @story_group = StoryGroup.new(story_group_params)

    if @story_group.save
      redirect_to @story_group, notice: 'Story group was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /story_groups/1
  def update
    if @story_group.update(story_group_params)
      redirect_to @story_group, notice: 'Story group was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/1
  def destroy
    @story_group.destroy!
    redirect_to story_groups_path, notice: 'Story group was successfully destroyed.', status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_story_group
    @story_group = StoryGroup.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def story_group_params
    params.expect(story_group: %i[owner_id name description icon currency_name currency_icon])
  end
end
