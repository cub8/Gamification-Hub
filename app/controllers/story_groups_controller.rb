# frozen_string_literal: true

class StoryGroupsController < ApplicationController
  # Fully converted to the "Card Table" redesign, #new included — it is the
  # four-step creation wizard now, the last screen to leave Bootstrap.
  # RedesignLayout is all-or-nothing (it cannot drop the layout for the modal
  # confirmations), hence its two lines inlined here.
  layout -> { @in_modal ? false : 'redesign' }
  # #show renders the same owned-item card and the same badge cards as the
  # inventory and the badge deck; under `include_all_helpers = false` their
  # helpers do not arrive on their own.
  helper RedesignHelper, StudentsItemsHelper, BadgesHelper

  before_action :set_presentation, only: %i[confirm_destroy destroy]
  before_action :set_story_group, only: %i[show edit update destroy confirm_destroy created]

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
  #
  # "Nowa grupa" — the one wizard in the app (DECISIONS.md:26). Four steps in a
  # single form; only the last one talks to the server before the submit, and
  # only to render the starter pack it is about to create.
  def new
    @story_group     = StoryGroup.new(default_lives: 3, ranking_mode: :podium_and_own)
    @focused         = true
    @group_art_layer = true

    authorize @story_group
  end

  # GET /story_groups/preset_preview
  #
  # Step 4's rows for the quick-start path, rendered into the frame that sits
  # INSIDE the wizard's form — so the teacher's edits and removals post with
  # everything else and the arithmetic never leaves Ruby.
  def preset_preview
    authorize StoryGroup, :new?

    @preset = Redesign::StarterPack.for(pack: params[:pack], classes: params[:classes])
    @currency_name = params[:currency_name]

    render partial: 'preset_review', layout: false
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
  #
  # The whole wizard arrives at once. The group and its starter pack share one
  # transaction: a group that exists with half a pack behind it is worse than
  # no group, and the teacher cannot see the difference from the outside.
  def create
    @story_group = StoryGroup.new(story_group_params)
    @story_group.owner_id = @current_user.id
    @focused              = true
    @group_art_layer      = true

    authorize @story_group

    if save_with_starter_pack
      # An ordinary redirect: the wizard is a page now, not the modal frame the
      # old form rendered into, so there is no frame to break out of.
      redirect_to created_story_group_path(@story_group)
    else
      render :new, status: :unprocessable_content
    end
  end

  # GET /story_groups/1/created
  #
  # The wizard's success screen. Deliberately does NOT show a join code
  # (DECISIONS.md:57): codes are made in "Zaproszenia", when one is wanted.
  def created
    authorize @story_group, :edit?

    @focused = true
    @counts  = {
      ranks:      @story_group.ranks.count,
      badges:     @story_group.badges.kept.count,
      items:      @story_group.items.kept.count,
      categories: @story_group.activity_group_templates.kept
                  .sum { |template| template.categories.size },
    }
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
    notice = "Usunięto grupę #{name}."

    # From the dialog this has to break OUT of the frame it was submitted in.
    # A plain redirect is followed INSIDE `modal`, and the group list has no
    # frame by that name — so the dialog emptied, the page never moved, and the
    # group only looked deleted after a reload. Every other destroy in the app
    # answers this way; this one was the exception.
    return redirect_outside_turbo_frame(story_groups_path, notice: notice) if @in_modal

    redirect_to story_groups_path, notice: notice, status: :see_other
  end

  private

  # True only when the teacher asked for the starter pack on step 3.
  def quick_start?
    params.dig(:setup, :path) == 'quick'
  end

  # The group and its pack in ONE transaction, so a pack that cannot be built
  # takes the group down with it rather than leaving a half-furnished group
  # behind. Returns false with the error already on the record, which is all
  # #create needs to re-render.
  def save_with_starter_pack
    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @story_group.save

      next true unless quick_start?

      StarterPackBuilder.new(story_group: @story_group,
                             pack:        params.dig(:setup, :pack),
                             classes:     params.dig(:setup, :classes),
                             selection:   starter_selection,).call
      true
    end
  rescue StarterPackBuilder::InvalidSelection => e
    @story_group.errors.add(:base, e.message)
    false
  end

  # The step-4 rows, out of the flat params the form posts and into the nested
  # shape StarterPackBuilder reads. Indices are the preset's own, written into
  # the markup server-side, so they always line up with the catalogue.
  #
  # Permitted by hand rather than with `expect`: the keys are numeric indices,
  # so there is no fixed list to name.
  def starter_selection
    setup = params[:setup]
    return {} if setup.blank?

    %i[ranks badges items cats].index_with do |zone|
      rows = setup[zone]
      next {} if rows.blank?

      rows.to_unsafe_h.to_h do |index, row|
        [index.to_i, { keep: row[:keep].to_s != '0', value: row[:value] }]
      end
    end
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
        ranking_enabled
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
