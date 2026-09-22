# frozen_string_literal: true

class StudentsController < ApplicationController
  include StoryGroupAuthorization
  include RedesignLayout

  # The list and the sheet are pages; editing and the removal confirmation are
  # dialogs. `new` is the exception: "Dodaj studenta" is still the Bootstrap
  # screen, so it keeps the Bootstrap layout until its own conversion.
  layout -> { layout_for_action }

  # The sheet renders the item, badge and ledger partials, and with
  # `include_all_helpers = false` none of those helpers arrive on their own.
  helper ItemsHelper, BadgesHelper, CurrencyTransactionsHelper, StudentsItemsHelper

  before_action :set_story_group
  # Teacher only. A student reaches their own numbers through the profile, the
  # shop and their own history, never through this list.
  before_action :authorize_story_group_manage!
  before_action :set_presentation, only: %i[edit confirm_destroy]
  before_action :set_student, only: %i[show edit update destroy update_lives confirm_destroy]

  # GET /story_groups/:story_group_id/students
  def index
    @list = Redesign::StudentList.new(story_group: @story_group)
  end

  # GET /story_groups/:story_group_id/students/:id
  def show
    @tab   = Redesign::StudentSheet.tab_for(params[:tab])
    @sheet = sheet
    @kind  = ledger_kind
  end

  # GET /story_groups/:story_group_id/students/new
  #
  # Still Bootstrap. Left untouched on purpose — see `layout_for_action`.
  def new
    @student = @story_group.student_memberships.build
    set_students_for_select
  end

  # GET /story_groups/:story_group_id/students/:id/edit
  def edit; end

  # GET /story_groups/:story_group_id/students/:id/confirm_destroy
  #
  # Removing a membership is a hard delete and cascades through the badges, the
  # purchases and the whole ledger, so the dialog needs those counts.
  def confirm_destroy
    @sheet = sheet
  end

  # POST /story_groups/:story_group_id/students
  def create
    @student = @story_group.student_memberships.build(create_student_params)

    if @student.save
      redirect_outside_turbo_frame story_group_students_path(@story_group),
                                   notice: 'Pomyślnie dodano studenta do grupy.'
    else
      set_students_for_select
      render :new, status: :unprocessable_content
    end
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
  #
  # The stepper on the list. The buttons stop at zero, so a failure here means
  # a hand-built request rather than a slip.
  def update_lives
    change = params[:change].to_i

    if @student.update_lives(change)
      redirect_to story_group_students_path(@story_group), notice: lives_notice
    else
      redirect_to story_group_students_path(@story_group),
                  alert: 'Nie można odebrać życia — student ma już 0.'
    end
  end

  # DELETE /story_groups/:story_group_id/students/:id
  def destroy
    name = @student.display_name
    @student.destroy

    # Nominative, for the same reason the dialog's heading has no name in it:
    # "Usunięto Anna Kowalska" would be the wrong case and there is no way to
    # decline a name here.
    redirect_outside_turbo_frame story_group_students_path(@story_group),
                                 notice: "#{name} nie należy już do grupy."
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_student
    @student = @story_group.student_memberships.with_user.find(params.expect(:id))
  end

  # Two frames reach this controller: `modal` for the edit dialog and `modal2`
  # for the removal confirmation it raises over itself. Each view names its own
  # frame; all this decides is dialog-or-page.
  def set_presentation
    @in_modal = %w[modal modal2].include?(turbo_frame_request_id)
  end

  def sheet
    @sheet ||= Redesign::StudentSheet.new(student: @student)
  end

  # `new` is the one action still rendering a Bootstrap view; everything else is
  # either a redesign page or a fragment for the dialog frame.
  def layout_for_action
    return 'application' if %w[new create].include?(action_name)

    @in_modal ? false : 'redesign'
  end

  # The ledger tab's filter, as a kind or nil for "Wszystkie".
  def ledger_kind
    kinds = Redesign::CurrencyLedger::KINDS.map(&:first).compact
    kinds.include?(params[:kind]) ? params[:kind] : nil
  end

  # "Sebastian Alejandro ma teraz 2 życia." — the lives change is the only thing
  # this form and this stepper can do, so the toast says the result rather than
  # "zapisano".
  def lives_notice
    lives = @student.lives.to_i

    "#{@student.display_name} ma teraz #{lives} #{helpers.gh_plural(lives, 'życie', 'życia', 'żyć')}."
  end

  def set_students_for_select
    @students =
      if @current_user.global_admin?
        User.all
      else
        User.where(university_name: @current_user.university_name)
      end
  end

  def create_student_params
    params.expect(story_group_student: %i[user_id])
  end

  def update_student_params
    params.expect(story_group_student: %i[lives])
  end
end
