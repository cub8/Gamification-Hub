# frozen_string_literal: true

class BadgesController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_read!,   only: :index
  before_action :authorize_story_group_manage!, except: :index
  before_action :set_presentation, only: :confirm_destroy
  before_action :set_badge, only: %i[edit update destroy confirm_destroy]

  def index
    @shelf = BadgeShelf.new(story_group: @story_group,
                            membership:  gh_group_chrome&.student_membership,)
  end

  def new
    @badge = @story_group.badges.build(discount:   0,
                                       icon_glyph: Glyphs::BADGE.first,)
    set_shelf
  end

  def edit
    set_shelf
  end

  def confirm_destroy
    @unlocking_items = @badge.unlocking_items.order(:name).to_a
  end

  def create
    @badge = @story_group.badges.build(badge_params)

    if @badge.save
      redirect_to story_group_badges_path(@story_group), notice: "Dodano odznakę „#{@badge.name}”."
    else
      set_shelf
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @badge.update(badge_params)
      redirect_to story_group_badges_path(@story_group), notice: "Zapisano odznakę „#{@badge.name}”."
    else
      set_shelf
      render :edit, status: :unprocessable_content
    end
  end

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

  def set_badge
    @badge = @story_group.badges.kept.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def set_shelf
    @shelf = BadgeShelf.new(story_group: @story_group)
  end

  def gh_group_chrome
    @gh_group_chrome ||= GroupChrome.for(user:        @current_user,
                                         story_group: @story_group,)
  end

  def badge_params
    permitted = params.expect(
      badge: %i[name story_description didactic_description discount icon_glyph icon],
    )

    permitted[:icon_glyph] = permitted[:icon_glyph].presence if permitted.key?(:icon_glyph)
    permitted[:icon_glyph] = nil if permitted[:icon].present?
    permitted
  end
end
