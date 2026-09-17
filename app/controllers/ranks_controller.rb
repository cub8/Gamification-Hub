# frozen_string_literal: true

class RanksController < ApplicationController
  include StoryGroupAuthorization
  include RedesignLayout

  # Only the delete confirmation is a dialog. Creating and editing are PAGES
  # (DECISIONS.md:26, "Forms: pages (not modals) for create/edit") — the form
  # carries a live preview column beside it, which no dialog is wide enough for.
  layout -> { @in_modal ? false : 'redesign' }

  before_action :set_story_group
  before_action :authorize_story_group_read!,   only: :index
  before_action :authorize_story_group_manage!, except: :index
  before_action :set_presentation, only: :confirm_destroy
  before_action :set_rank, only: %i[edit update destroy confirm_destroy]

  # GET /story_groups/:story_group_id/ranks
  #
  # One screen, two personas — the teacher's editable ladder and the student's
  # progress through it. Which one you get is decided by MEMBERSHIP, through the
  # same object the navigation chrome uses, so the page and the deck beside it
  # cannot disagree about who you are here.
  def index
    @ladder = Redesign::RankLadder.new(story_group: @story_group,
                                       membership:  gh_group_chrome&.student_membership,)
  end

  # GET /story_groups/:story_group_id/ranks/new
  def new
    # Both numbers start at 0. A group need not have a rank at 0 — its first
    # rung may well sit at 20 or 30 — so 0 is an offer, not a reservation.
    @rank = @story_group.ranks.build(required_currency_value: 0,
                                     discount:                0,
                                     icon_glyph:              Redesign::Glyphs::RANK.first,)
    set_ladder
  end

  # GET /story_groups/:story_group_id/ranks/:id/edit
  def edit
    set_ladder
  end

  # GET /story_groups/:story_group_id/ranks/:id/confirm_destroy
  def confirm_destroy
    @dependent_items = @rank.dependent_items.order(:name).to_a
  end

  # POST /story_groups/:story_group_id/ranks
  def create
    @rank = @story_group.ranks.build(rank_params)

    if @rank.save
      redirect_to story_group_ranks_path(@story_group), notice: "Dodano rangę „#{@rank.name}”."
    else
      set_ladder
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /story_groups/:story_group_id/ranks/:id
  def update
    if @rank.update(rank_params)
      redirect_to story_group_ranks_path(@story_group), notice: "Zapisano rangę „#{@rank.name}”."
    else
      set_ladder
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/:story_group_id/ranks/:id
  #
  # Re-checked here and not only in the dialog: items.unlock_rank_id and
  # items.min_rank_for_discount_id are real foreign keys, so destroying a
  # referenced rank raises rather than cascading. The disabled button in the
  # dialog is a courtesy; this is the rule.
  def destroy
    name = @rank.name
    blockers = @rank.dependent_items.order(:name).pluck(:name)

    if blockers.any?
      return redirect_outside_turbo_frame story_group_ranks_path(@story_group),
                                          alert: "Nie można usunąć rangi „#{name}”: wymagają jej " \
                                                 "przedmioty #{helpers.gh_and_list(blockers)}."
    end

    @rank.destroy
    redirect_outside_turbo_frame story_group_ranks_path(@story_group),
                                 notice: "Usunięto rangę „#{name}”."
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_rank
    @rank = @story_group.ranks.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  # The form's preview needs the rungs the draft will land among. Built here
  # rather than in the view so a re-render after a validation error gets it too.
  def set_ladder
    @ladder = Redesign::RankLadder.new(story_group: @story_group)
  end

  # Assigns RedesignHelper's own memo, so the layout's chrome and this action
  # resolve the membership once between them rather than twice.
  def gh_group_chrome
    @gh_group_chrome ||= Redesign::GroupChrome.for(user:        @current_user,
                                                   story_group: @story_group,)
  end

  def rank_params
    permitted = params.expect(rank: %i[name discount required_currency_value icon_glyph icon])

    # An empty key means "use my upload" — the picker's eleventh tile. NULL is
    # how the record says that, so normalise here rather than teaching the model
    # about a blank string.
    permitted[:icon_glyph] = permitted[:icon_glyph].presence if permitted.key?(:icon_glyph)

    # A file in this submission always wins. You just chose it, so it is the
    # art — and without JavaScript nothing else would ever select it, because
    # the picker's own tile only appears once there is something attached.
    # Choosing a preset later switches back without losing the upload.
    permitted[:icon_glyph] = nil if permitted[:icon].present?
    permitted
  end
end
