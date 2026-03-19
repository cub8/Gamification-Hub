# frozen_string_literal: true

class StoryGroupsController < ApplicationController
  before_action :authorize
  before_action :set_story_group, only: %i[show edit update destroy]

  # GET /story_groups
  def index
    if @current_user&.university_teacher?
      @story_groups = @current_user.story_groups
    elsif @current_user&.university_admin? || @current_user&.global_admin?
      @story_groups = StoryGroup.all
      # Na razie nie ma różnicy między global a university adminem,
      # to gdy będziemy już mieć tabelkę z uniwersytetami
    end
  end

  # GET /story_groups/1
  def show; end

  # GET /story_groups/new
  def new
    unless @current_user&.university_teacher?
      redirect_to story_groups_path, alert: 'Creating story groups is only possible for teachers'
    end

    @story_group = StoryGroup.new
  end

  # GET /story_groups/1/edit
  def edit; end

  # POST /story_groups
  def create
    return unless @current_user&.university_teacher?

    @story_group = StoryGroup.new(story_group_params)
    @story_group.owner_id = @current_user.id

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
    if @current_user&.university_teacher?
      @story_group = @current_user.story_groups.find(params.expect(:id))
    elsif @current_user&.university_admin? || @current_user&.global_admin?
      @story_group = StoryGroup.find(params.expect(:id))
    end
  end

  # Only allow a list of trusted parameters through.
  def story_group_params
    params.expect(story_group: %i[name description icon currency_name currency_icon])
  end

  def authorize
    return if @current_user&.university_teacher?
    return if @current_user&.university_admin?
    return if @current_user&.global_admin?

    redirect_to root_path, alert: 'You must be a teacher or admin to access story groups'

  end
end
