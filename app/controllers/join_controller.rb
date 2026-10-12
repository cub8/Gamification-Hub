# frozen_string_literal: true

class JoinController < ApplicationController
  before_action :set_presentation

  def new; end

  def lookup
    @code = params[:code]
    @lookup = InviteLookup.new(user: current_user, code: @code).call

    return render :new, status: :unprocessable_content unless @lookup.ok?

    @story_group = @lookup.story_group
    render :show
  end

  def show
    @code = params[:code]
    @lookup = InviteLookup.new(user: current_user, code: @code).call

    return render :new, status: :unprocessable_content unless @lookup.ok?

    @story_group = @lookup.story_group
  end

  def create
    @code = params[:code]
    @lookup = InviteLookup.new(user: current_user, code: @code).call

    return render :new, status: :unprocessable_content unless @lookup.ok?

    accept!
  end

  def done
    @story_group = current_user.student_story_groups.find(params[:story_group_id])
    @membership = current_user.student_memberships.find_by!(story_group: @story_group)

    render :create
  end

  private

  def accept!
    service = AcceptInviteService.new(
      user:     current_user,
      invite:   @lookup.invite,
      nickname: params[:nickname],
    )

    @result = service.call
    @story_group = @result.story_group

    return render :show, status: :unprocessable_content unless @result.success?

    redirect_to done_join_index_path(story_group_id: @story_group.id)
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
    @chrome = false unless @in_modal
  end
end
