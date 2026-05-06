# frozen_string_literal: true

class StoryGroupInvitesController < ApplicationController
  include StoryGroupAuthorization

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_invite, only: %i[show edit update destroy]

  def index
    @invites = policy_scope(@story_group.invites)
  end

  def show; end

  def new
    @invite = @story_group.invites.build
  end

  def edit; end

  def create
    @invite = @story_group.invites.build(invite_params)

    if @invite.save
      redirect_to story_group_invites_path(@story_group),
                  notice: 'Invite was successfully added to story group.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @invite.update(invite_params)
      redirect_to story_group_invites_path(@story_group),
                  notice: 'Invite was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @invite.destroy

    redirect_to story_group_invites_path(@story_group),
                notice: 'Invite was successfully removed from story group.'
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_invite
    @invite = @story_group.invites.find(params.expect(:id))
  end

  def invite_params
    params.expect(
      story_group_invite: %i[
        expires_at
        max_uses
      ],
    )
  end
end
