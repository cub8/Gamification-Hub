# frozen_string_literal: true

class RankingController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :set_presentation,              only: %i[confirm_visibility confirm_mode]
  before_action :authorize_story_group_manage!, except: :show

  def show
    authorize @story_group, :view_ranking?
    skip_policy_scope

    @board = RankingBoard.new(story_group: @story_group,
                              membership:  gh_group_chrome&.student_membership,)
  end

  def confirm_visibility
    @enabled = params[:enabled] == 'true'
    @mode    = @story_group.ranking_mode
  end

  def confirm_mode
    @mode = params[:mode]
    raise ActiveRecord::RecordNotFound unless StoryGroup.ranking_modes.key?(@mode)
  end

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

  def notice_for_update
    return 'Ranking ukryty przed studentami.' unless @story_group.ranking_enabled?
    return 'Ranking widoczny w całości.' if @story_group.ranking_full?

    'Ranking widoczny: podium i własne miejsce.'
  end

  def gh_group_chrome
    @gh_group_chrome ||= GroupChrome.for(user: @current_user, story_group: @story_group)
  end
end
