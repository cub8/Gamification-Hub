# frozen_string_literal: true

class StoryGroupsController < ApplicationController
  # Only #index is converted to the "Card Table" redesign. #show, #new and
  # #edit still render Bootstrap markup and so stay on the application layout.
  # RedesignLayout is all-or-nothing, hence its two lines inlined here instead
  # of `include RedesignLayout`.
  layout 'redesign', only: :index
  helper RedesignHelper

  before_action :set_story_group, only: %i[show edit update destroy]

  # GET /story_groups
  def index
    scope = policy_scope(StoryGroup)

    @listing = StoryGroupsListing.new(scope: scope, user: current_user, filter: params[:filter]).load
  end

  # GET /story_groups/1
  def show
    authorize @story_group
    @student = @story_group.student_memberships.find_by(user_id: @current_user.id)

    if @student
      dashboard       = StoryGroupStudentDashboard.new(student: @student).load
      @rank           = dashboard.rank
      @badges         = dashboard.badges
      @students_items = dashboard.students_items
    else
      dashboard                = StoryGroupTeacherDashboard.new(story_group: @story_group).load
      @recent_transactions     = dashboard.recent_transactions
      @recent_activity_groups  = dashboard.recent_activity_groups
      @activity_group_rankings = dashboard.activity_group_rankings
    end
  end

  # GET /story_groups/new
  def new
    @story_group = StoryGroup.new
    authorize @story_group
  end

  # GET /story_groups/1/edit
  def edit
    authorize @story_group
  end

  # POST /story_groups
  def create
    @story_group = StoryGroup.new(story_group_params)
    @story_group.owner_id = @current_user.id

    authorize @story_group

    if @story_group.save
      redirect_outside_turbo_frame story_group_path(@story_group),
                                   notice: 'Pomyślnie utworzono grupę fabularną.'
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /story_groups/1
  def update
    authorize @story_group

    if @story_group.update(story_group_params)
      redirect_outside_turbo_frame story_group_path(@story_group),
                                   notice: 'Pomyślnie zaktualizowano grupę fabularną.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/1
  def destroy
    authorize @story_group

    @story_group.destroy!
    redirect_to story_groups_path, notice: 'Pomyślnie usunięto grupę fabularną.', status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_story_group
    @story_group = StoryGroup.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def story_group_params
    params.expect(
      story_group: %i[
        name
        description
        icon
        currency_name
        currency_icon
        default_lives
      ],
    )
  end
end
