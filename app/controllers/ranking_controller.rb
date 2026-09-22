# frozen_string_literal: true

# "Ranking" (mockup #/t/ranking and #/s/ranking): one group's students ordered
# by what they have collected.
#
# One action, two screens. Which one you get is decided by MEMBERSHIP, through
# the same object the navigation chrome uses, so the page and the deck beside it
# cannot disagree about who you are here — the same rule RanksController and
# BadgesController follow.
#
# Everything a teacher can change about what students see is confirmed in a
# dialog first (DECISIONS.md:36). The four transitions each get their own
# sentence, because "Pokazać pełny ranking?" and "Ukryć ranking?" warn about
# opposite things.
class RankingController < ApplicationController
  include StoryGroupAuthorization
  include RedesignLayout

  # Only the confirmations are dialogs, and inside a dialog only the frame is
  # used — the redesign layout already carries a <turbo-frame id="modal">.
  layout -> { @in_modal ? false : 'redesign' }

  before_action :set_story_group
  before_action :set_presentation,              only: %i[confirm_visibility confirm_mode]
  before_action :authorize_story_group_manage!, except: :show

  # GET /story_groups/:story_group_id/ranking
  def show
    authorize @story_group, :view_ranking?
    skip_policy_scope

    @board = Redesign::RankingBoard.new(story_group: @story_group,
                                        membership:  gh_group_chrome&.student_membership,)
  end

  # GET /story_groups/:story_group_id/ranking/confirm_visibility?enabled=true
  #
  # Showing the board and hiding it are the same switch and two different
  # warnings, so one action renders both: `enabled` is what the teacher is
  # asking for, not what is set now.
  def confirm_visibility
    @enabled = params[:enabled] == 'true'
    # Only asked for when turning the board ON; the dialog offers it as a
    # choice, preselected to whatever the group already carries.
    @mode    = @story_group.ranking_mode
  end

  # GET /story_groups/:story_group_id/ranking/confirm_mode?mode=full
  def confirm_mode
    @mode = params[:mode]
    raise ActiveRecord::RecordNotFound unless StoryGroup.ranking_modes.key?(@mode)
  end

  # PATCH /story_groups/:story_group_id/ranking
  #
  # The only writer. Every dialog posts here with the setting it just confirmed,
  # so there is one place that changes what students see.
  def update
    @story_group.update!(ranking_params)

    redirect_outside_turbo_frame story_group_ranking_path(@story_group), notice: notice_for_update
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end

  def ranking_params
    params.expect(story_group: %i[ranking_enabled ranking_mode])
  end

  # The mockup's own toasts (30-rk.js `vis`, `doEnable`, `mode`, `doFull`): each
  # one says what students can see now, which is the thing the teacher just
  # changed and cannot check from their own screen.
  def notice_for_update
    return 'Ranking ukryty przed studentami.' unless @story_group.ranking_enabled?
    return 'Ranking widoczny w całości.' if @story_group.ranking_full?

    'Ranking widoczny: podium i własne miejsce.'
  end

  # Assigns RedesignHelper's own memo, so the layout's chrome and this action
  # resolve the membership once between them rather than twice.
  def gh_group_chrome
    @gh_group_chrome ||= Redesign::GroupChrome.for(user: @current_user, story_group: @story_group)
  end
end
