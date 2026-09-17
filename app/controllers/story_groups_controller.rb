# frozen_string_literal: true

class StoryGroupsController < ApplicationController
  # The list, the overview and the settings page are converted to the "Card
  # Table" redesign; #new still renders Bootstrap markup and so stays on the
  # application layout. RedesignLayout is all-or-nothing, hence its two lines
  # inlined here instead of `include RedesignLayout`.
  layout -> { layout_for_action }
  # #show renders the same owned-item card and the same badge cards as the
  # inventory and the badge deck; under `include_all_helpers = false` their
  # helpers do not arrive on their own.
  helper RedesignHelper, StudentsItemsHelper, BadgesHelper

  before_action :set_presentation, only: %i[confirm_destroy destroy]
  before_action :set_story_group, only: %i[show edit update destroy confirm_destroy]

  # GET /story_groups
  def index
    scope = policy_scope(StoryGroup)

    @listing = StoryGroupsListing.new(scope: scope, user: current_user, filter: params[:filter]).load
  end

  # GET /story_groups/1
  #
  # Two screens, chosen by MEMBERSHIP rather than by role: a teacher enrolled in
  # somebody else's group reads it as a student. This is the same question
  # Redesign::GroupChrome#student? asks for the sidebar, so the page and the
  # navigation beside it cannot disagree about who you are here.
  def show
    authorize @story_group
    @student = @story_group.student_memberships.find_by(user_id: @current_user.id)

    @overview = if @student
                  Redesign::StudentOverview.new(student: @student).load
                else
                  Redesign::TeacherOverview.new(story_group: @story_group).load
                end
  end

  # GET /story_groups/new
  def new
    @story_group = StoryGroup.new
    authorize @story_group
  end

  # GET /story_groups/1/edit
  #
  # "Ustawienia grupy" — a PAGE, not the dialog it used to be
  # (DECISIONS.md:26). Supporting teachers get here too; only the delete panel
  # inside is owner-only, which `destroy?` decides.
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
      # Back to the settings page, not to the group: this is a destination in
      # the sidebar now, and a teacher changing three things in a row should not
      # be thrown out of it after each one. An ordinary redirect, because the
      # form is a page and there is no turbo frame to escape.
      redirect_to edit_story_group_path(@story_group), notice: 'Zapisano ustawienia grupy.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  # GET /story_groups/1/confirm_destroy
  #
  # Deleting a group is the one cascade that takes everything with it
  # (DECISIONS.md:28), so the dialog counts who loses access and makes you type
  # the group's name back.
  def confirm_destroy
    authorize @story_group, :destroy?
  end

  # DELETE /story_groups/1
  def destroy
    authorize @story_group

    # The typed name is re-checked HERE, not just in the dialog. The disabled
    # button is the courtesy; this is what actually stands between a stray
    # request and every purchase, badge and ledger row in the group.
    unless params[:confirm].to_s.strip == @story_group.name.to_s
      @confirm_failed = true
      return render :confirm_destroy, status: :unprocessable_content
    end

    name = @story_group.name
    @story_group.destroy!
    redirect_to story_groups_path, notice: "Usunięto grupę #{name}.", status: :see_other
  end

  private

  # `new` is the one action still rendering a Bootstrap view; the delete
  # confirmation drops the layout entirely when it answers into the dialog's
  # frame, because the redesign layout already carries a <turbo-frame id="modal">
  # and two with one id in a response let Turbo pick whichever came first.
  def layout_for_action
    return 'application' if %w[new create].include?(action_name)

    @in_modal ? false : 'redesign'
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_story_group
    @story_group = StoryGroup.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def story_group_params
    permitted = params.expect(
      story_group: %i[
        name
        description
        icon
        icon_glyph
        currency_name
        currency_icon
        currency_icon_glyph
        default_lives
        ranking_mode
      ],
    )

    normalise_art(permitted, :icon, :icon_glyph)
    normalise_art(permitted, :currency_icon, :currency_icon_glyph)
    permitted
  end

  # An empty key means "use my upload" — the picker's last tile. NULL is how the
  # record says that, so normalise here rather than teaching the model about a
  # blank string. A file in this submission always wins, because choosing one is
  # how you say you want it. Same rule as RanksController#rank_params.
  def normalise_art(permitted, attachment, glyph)
    permitted[glyph] = permitted[glyph].presence if permitted.key?(glyph)
    permitted[glyph] = nil if permitted[attachment].present?
  end
end
