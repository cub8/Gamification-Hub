# frozen_string_literal: true

class AcceptInviteService
  Result = Data.define(:success, :membership, :reason, :story_group) do
    def initialize(success: false, membership: nil, reason: nil, story_group: nil)
      super
    end

    def success? = success

    def nickname_error = membership && membership.errors[:nickname].first
  end

  def initialize(user:, invite:, nickname: nil)
    @current_user = user
    @invite = invite
    @story_group = invite.story_group
    # Not normalised here any more: StoryGroupStudent#normalise_nickname owns
    # the blank-means-NULL rule, because the settings screen writes this column
    # too and the partial unique index depends on it.
    @nickname = nickname
  end

  def call
    @invite.with_lock do
      recheck = InviteLookup.new(user: @current_user, code: @invite.code).call

      if recheck.ok?
        save_membership
      else
        Result.new(reason: recheck.reason || :already_member, story_group: @story_group)
      end
    end
  end

  private

  def save_membership
    membership = @story_group.student_memberships.build(user: @current_user, nickname: @nickname)

    if membership.save
      @invite.use!
      Result.new(success: true, membership: membership, story_group: @story_group)
    else
      Result.new(membership: membership, reason: :invalid, story_group: @story_group)
    end
  end
end
