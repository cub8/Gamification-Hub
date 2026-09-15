# frozen_string_literal: true

class BadgesController < ApplicationController
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
  before_action :set_badge, only: %i[edit update destroy confirm_destroy]

  # GET /story_groups/:story_group_id/badges
  #
  # One screen, two personas — the teacher's editable grid and the student's
  # deck of flip cards. Which one you get is decided by MEMBERSHIP, through the
  # same object the navigation chrome uses, so the page and the deck beside it
  # cannot disagree about who you are here.
  def index
    @shelf = Redesign::BadgeShelf.new(story_group: @story_group,
                                      membership:  gh_group_chrome&.student_membership,)
  end

  # GET /story_groups/:story_group_id/badges/new
  def new
    @badge = @story_group.badges.build(discount:   0,
                                       icon_glyph: Redesign::Glyphs::BADGE.first,)
    set_shelf
  end

  # GET /story_groups/:story_group_id/badges/:id/edit
  def edit
    set_shelf
  end

  # GET /story_groups/:story_group_id/badges/:id/confirm_destroy
  def confirm_destroy
    @unlocking_items = @badge.unlocking_items.order(:name).to_a
  end

  # POST /story_groups/:story_group_id/badges
  def create
    @badge = @story_group.badges.build(badge_params)

    if @badge.save
      redirect_to story_group_badges_path(@story_group), notice: "Dodano odznakę „#{@badge.name}”."
    else
      set_shelf
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /story_groups/:story_group_id/badges/:id
  def update
    if @badge.update(badge_params)
      redirect_to story_group_badges_path(@story_group), notice: "Zapisano odznakę „#{@badge.name}”."
    else
      set_shelf
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /story_groups/:story_group_id/badges/:id
  #
  # Soft, unlike ranks (DECISIONS.md:54). Nothing can refuse it: the badge only
  # leaves the lists, the pickers and the award dialog, and every students_badges
  # row pointing at it stays exactly where it was.
  def destroy
    name = @badge.name
    @badge.soft_delete!

    redirect_outside_turbo_frame story_group_badges_path(@story_group),
                                 notice: "Usunięto odznakę „#{name}”. Studenci, " \
                                         'którzy ją mają, zachowują ją w historii.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  # `kept`: a deleted badge has no edit page and no delete page of its own.
  def set_badge
    @badge = @story_group.badges.kept.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  # The form's preview needs the holder count and the items that lean on this
  # badge. Built here rather than in the view so a re-render after a validation
  # error gets it too.
  def set_shelf
    @shelf = Redesign::BadgeShelf.new(story_group: @story_group)
  end

  # Assigns RedesignHelper's own memo, so the layout's chrome and this action
  # resolve the membership once between them rather than twice.
  def gh_group_chrome
    @gh_group_chrome ||= Redesign::GroupChrome.for(user:        @current_user,
                                                   story_group: @story_group,)
  end

  def badge_params
    permitted = params.expect(
      badge: %i[name story_description didactic_description discount icon_glyph icon],
    )

    # An empty key means "use my upload" — the picker's last tile. NULL is how
    # the record says that, so normalise here rather than teaching the model
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
