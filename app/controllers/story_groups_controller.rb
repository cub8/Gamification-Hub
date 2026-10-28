# frozen_string_literal: true

class StoryGroupsController < ApplicationController
  # #show renders the same owned-item card and the same badge cards as the
  # inventory and the badge deck; under `include_all_helpers = false` their
  # helpers do not arrive on their own.
  helper StudentsItemsHelper, BadgesHelper

  before_action :set_presentation, only: %i[confirm_destroy destroy]
  before_action :set_story_group, only: %i[show edit update destroy confirm_destroy created]

  # GET /story_groups
  def index
    scope = policy_scope(StoryGroup)

    @listing = StoryGroupsListing.new(scope: scope, user: current_user, filter: params[:filter]).load
  end

  def show
    authorize @story_group
    @student = @story_group.student_memberships.find_by(user_id: @current_user.id)

    @overview = if @student
                  StudentOverview.new(student: @student).load
                else
                  TeacherOverview.new(story_group: @story_group).load
                end
  end

  def new
    @story_group     = StoryGroup.new(default_lives: 3, ranking_mode: :podium_and_own)
    @focused         = true
    @group_art_layer = true

    authorize @story_group
  end

  def preset_preview
    authorize StoryGroup, :new?

    @preset = StarterPack.for(pack: params[:pack], classes: params[:classes])
    @currency_name = params[:currency_name]

    render partial: 'preset_review', layout: false
  end

  def edit
    authorize @story_group
  end

  def create
    @story_group = StoryGroup.new(story_group_params)
    @story_group.owner_id = @current_user.id
    @focused              = true
    @group_art_layer      = true

    authorize @story_group

    if save_with_starter_pack
      options = @csv_warnings.present? ? { alert: @csv_warnings.join(' ') } : {}
      redirect_to created_story_group_path(@story_group), **options
    else
      @setup_path = params.dig(:setup, :path)
      render :new, status: :unprocessable_content
    end
  end

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

  def update
    authorize @story_group

    if @story_group.update(story_group_params)
      redirect_to edit_story_group_path(@story_group), notice: 'Zapisano ustawienia grupy.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def confirm_destroy
    authorize @story_group, :destroy?
  end

  def destroy
    authorize @story_group

    unless params[:confirm].to_s.strip == @story_group.name.to_s
      @confirm_failed = true
      return render :confirm_destroy, status: :unprocessable_content
    end

    name = @story_group.name
    @story_group.destroy!
    notice = "Usunięto grupę #{name}."

    return redirect_outside_turbo_frame(story_groups_path, notice: notice) if @in_modal

    redirect_to story_groups_path, notice: notice, status: :see_other
  end

  private

  def quick_start?
    params.dig(:setup, :path) == 'quick'
  end

  def csv_start?
    params.dig(:setup, :path) == 'csv'
  end

  def save_with_starter_pack
    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @story_group.save

      if quick_start?
        StarterPackBuilder.new(story_group: @story_group,
                               pack:        params.dig(:setup, :pack),
                               classes:     params.dig(:setup, :classes),
                               selection:   starter_selection,).call
      elsif csv_start?
        build_from_csv
      end

      true
    end
  rescue StarterPackBuilder::InvalidSelection => e
    @story_group.errors.add(:base, e.message)
    false
  rescue Csv::MalformedFile
    @story_group.errors.add(:base, 'Nie udało się odczytać jednego z wgranych plików CSV.')
    false
  rescue ActiveRecord::RecordInvalid => e
    @story_group.errors.add(:base, "Import się nie powiódł: #{e.record.errors.full_messages.to_sentence}")
    false
  end

  def build_from_csv
    preset = Csv::GroupPresetParser.new(csv_files, story_group: @story_group).call
    StarterPackBuilder.new(story_group: @story_group, preset: preset).call
    @csv_warnings = preset.warnings
  end

  def csv_files
    files = params.dig(:setup, :csv) || {}

    %i[ranks badges items templates]
      .index_with { |key| files[key] }
      .compact
  end

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

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:id))
  end

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

    normalize_art(permitted, :icon, :icon_glyph)
    normalize_art(permitted, :currency_icon, :currency_icon_glyph)
    permitted
  end

  def normalize_art(permitted, attachment, glyph)
    permitted[glyph] = permitted[glyph].presence if permitted.key?(glyph)
    permitted[glyph] = nil if permitted[attachment].present?
  end
end
