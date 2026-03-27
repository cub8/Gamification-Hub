# frozen_string_literal: true

class StoryGroupsController < ApplicationController
  before_action :set_story_group, only: %i[show edit update destroy]
  before_action :authorize, only: %i[new create edit update destroy]

  # GET /story_groups
  def index
    if @current_user&.teacher?
      @story_groups = @current_user.story_groups
    elsif @current_user&.organization_admin? || @current_user&.global_admin?
      @story_groups = StoryGroup.all
      # Na razie nie ma różnicy między global a university adminem,
      # to gdy będziemy już mieć tabelkę z uniwersytetami
    end
  end

  # GET /story_groups/1
  def show; end # set_story_groups weryfikuje przynależność story_group do nauczyciela

  # GET /story_groups/new
  def new
    @story_group = StoryGroup.new
  end

  # GET /story_groups/1/edit
  def edit; end # set_story_groups weryfikuje przynależność story_group do nauczyciela

  # POST /story_groups
  def create
    @story_group = StoryGroup.new(story_group_params)
    @story_group.owner_id = @current_user.id

    if @story_group.save
      redirect_to @story_group, notice: 'Story group was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /story_groups/1
  def update # set_story_groups weryfikuje przynależność story_group do nauczyciela
    if @story_group.update(story_group_params)
      redirect_to @story_group, notice: 'Story group was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/1
  def destroy # set_story_groups weryfikuje przynależność story_group do nauczyciela
    @story_group.destroy!
    redirect_to story_groups_path, notice: 'Story group was successfully destroyed.', status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_story_group
    if @current_user&.teacher?
      @story_group = @current_user.story_groups.find(params.expect(:id))
    elsif @current_user&.organization_admin? || @current_user&.global_admin?
      @story_group = StoryGroup.find(params.expect(:id))
    end
  end

  # Only allow a list of trusted parameters through.
  def story_group_params
    params.expect(story_group: %i[name description icon currency_name currency_icon])
  end

  def authorize
    return if @story_group.nil? && (@current_user.teacher? || @current_user.organization_admin?)
    return if @story_group && @current_user.has_access_to_story_group?(@story_group)

    redirect_to root_path, 'Not found'
  end

end
