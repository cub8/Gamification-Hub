# frozen_string_literal: true

class StoryGroupInvitesController < ApplicationController
  include StoryGroupAuthorization

  # Unlike JoinController this never sets `@chrome = false`: joining is a
  # focused flow, while these are in-app screens that keep the shell when they
  # are opened as pages rather than dialogs.

  before_action :set_story_group
  before_action :authorize_story_group_manage!
  before_action :set_presentation
  before_action :set_invite, only: %i[show edit update destroy confirm_destroy]

  def index
    invites = policy_scope(@story_group.invites).order(created_at: :desc)

    # Grouped on a computed status, never a column: "active" depends on the
    # clock as much as on the row (30-isg.js:28).
    @active, @inactive = invites.partition(&:active?)
    @fresh_invite_id   = flash[:fresh_invite]
  end

  def show; end

  # "Pokaż kod dla studentów" (students#index). Not scoped to one invite —
  # every active one, newest first, so the teacher can flip between them
  # without leaving the dialog.
  def quick
    invites = policy_scope(@story_group.invites).order(created_at: :desc)
    @active = invites.select(&:active?)
  end

  def confirm_destroy; end

  def new
    @form = InviteForm.for(@story_group.invites.build)
  end

  def edit
    @form = InviteForm.for(@invite)
  end

  def create
    @form = InviteForm.from_params(@story_group.invites.build, params)
    return render :new, status: :unprocessable_content unless @form.save

    # DECISIONS.md: a new invite is NOT auto-shown. The notice is the whole
    # nudge, and the row flashes once on the list behind it.
    flash[:fresh_invite] = @form.invite.id
    redirect_outside_turbo_frame story_group_invites_path(@story_group),
                                 notice: "Utworzono kod #{@form.invite.code}. " \
                                         'Kliknij „Pokaż”, żeby wyświetlić go studentom.'
  end

  def update
    @form = InviteForm.from_params(@invite, params)
    return render :edit, status: :unprocessable_content unless @form.save

    redirect_outside_turbo_frame story_group_invites_path(@story_group),
                                 notice: "Zapisano zaproszenie #{@invite.code}."
  end

  def destroy
    code = @invite.code
    @invite.destroy

    # Submitted from inside the dialog, so it has to break out of the frame the
    # same way create and update do.
    redirect_outside_turbo_frame story_group_invites_path(@story_group),
                                 notice: "Usunięto zaproszenie #{code}."
  end

  private

  def set_story_group
    @story_group = StoryGroup.find(params.expect(:story_group_id))
  end

  def set_invite
    @invite = @story_group.invites.find(params.expect(:id))
  end

  def set_presentation
    @in_modal = turbo_frame_request_id == 'modal'
  end
end
