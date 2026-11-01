# frozen_string_literal: true

class StudentsController < ApplicationController
  include StoryGroupAuthorization

  helper ItemsHelper, BadgesHelper, CurrencyTransactionsHelper, StudentsItemsHelper

  before_action :set_story_group
  # Teacher only. A student reaches their own numbers through the profile, the
  # shop and their own history, never through this list.
  before_action :authorize_story_group_manage!
  before_action :set_presentation, only: %i[edit confirm_destroy]
  before_action :set_student, only: %i[show edit update destroy update_lives confirm_destroy]

  # GET /story_groups/:story_group_id/students
  def index
    @list     = StudentList.new(story_group: @story_group)
    @selected = { rank: filter_param(:rank), item: filter_param(:item), badge: filter_param(:badge) }
  end

  def new_import; end

  def import
    file = params[:file]
    return redirect_with_alert(t('shared.csv_import.select_file')) unless file

    @result = Csv::StudentsImporter.new(story_group: @story_group, file: file).call

    render :import
  rescue Csv::MalformedFile
    redirect_with_alert(t('shared.csv_import.malformed_file'))
  end

  # GET /story_groups/:story_group_id/students/:id
  def show
    @tab   = StudentSheet.tab_for(params[:tab])
    @sheet = sheet
    @kind  = ledger_kind
  end

  # GET /story_groups/:story_group_id/students/:id/edit
  def edit; end

  # GET /story_groups/:story_group_id/students/:id/confirm_destroy
  def confirm_destroy
    @sheet = sheet
  end

  # PATCH/PUT /story_groups/:story_group_id/students/:id
  def update
    if @student.update(update_student_params)
      redirect_outside_turbo_frame story_group_student_path(@story_group, @student),
                                   notice: lives_notice
    else
      render :edit, status: :unprocessable_content
    end
  end

  # POST /story_groups/:story_group_id/students/:id/update_lives
  def update_lives
    change = params[:change].to_i

    if @student.update_lives(change)
      redirect_to story_group_students_path(@story_group), notice: lives_notice
    else
      redirect_to story_group_students_path(@story_group),
                  alert: t('students.flash.cannot_take_life')
    end
  end

  # DELETE /story_groups/:story_group_id/students/:id
  def destroy
    name = @student.display_name
    @student.destroy

    redirect_outside_turbo_frame story_group_students_path(@story_group),
                                 notice: t('students.flash.removed', name: name)
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_student
    @student = @story_group.student_memberships.with_user.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = %w[modal modal2].include?(turbo_frame_request_id)
  end

  def sheet
    @sheet ||= StudentSheet.new(student: @student)
  end

  def filter_param(key)
    Array(params[key]).grep(String).compact_blank
  end

  def ledger_kind
    kinds = CurrencyLedger::KINDS.compact
    kinds.include?(params[:kind]) ? params[:kind] : nil
  end

  def lives_notice
    t('students.flash.lives_notice', name: @student.display_name, count: @student.lives.to_i)
  end

  def update_student_params
    params.expect(story_group_student: %i[lives])
  end

  def redirect_with_alert(message)
    redirect_to new_import_story_group_students_path(@story_group), alert: message
  end
end
