# frozen_string_literal: true

class StoryGroupsController < ApplicationController
  before_action :set_story_group, only: %i[show edit update destroy]

  # GET /story_groups
  def index
    all_groups = policy_scope(StoryGroup)

    @story_groups = case params[:filter]
                    when 'mine'    then all_groups.where(owner_id: current_user.id)
                    when 'student' then all_groups.where(id: current_user.student_story_groups.select(:id))
                    when 'teacher' then all_groups.where(id: current_user.teacher_story_groups.select(:id))
                    else                all_groups
                    end.with_attached_icon

    @show_mine_tab    = all_groups.exists?(owner_id: current_user.id)
    @show_student_tab = current_user.student_story_groups.exists?
    @show_teacher_tab = current_user.teacher_story_groups.exists?
  end

  # GET /story_groups/1
  def show
    authorize @story_group
    @student = @story_group.student_memberships.find_by(user_id: @current_user.id)
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
