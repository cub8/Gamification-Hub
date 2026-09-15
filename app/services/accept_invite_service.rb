# frozen_string_literal: true

# Creates the membership behind an invite code.
#
# The write half of joining; InviteLookup is the read half. The code is checked
# again here, inside the row lock, because the check that rendered step 2 is a
# few seconds stale by the time the form comes back and the last seat may be
# gone.
class AcceptInviteService
  Result = Data.define(:success, :membership, :reason, :story_group) do
    def initialize(success: false, membership: nil, reason: nil, story_group: nil)
      super
    end

    def success? = success

    # Set only when the membership itself was rejected — a nickname already
    # taken in this group — so the form can put the message on the field
    # instead of turning it into "coś poszło nie tak".
    def nickname_error = membership && membership.errors[:nickname].first
  end

  def initialize(user:, invite:, nickname: nil)
    @current_user = user
    @invite = invite
    @story_group = invite.story_group
    @nickname = nickname.to_s.strip.presence
  end

  def call
    # with_lock is itself a transaction, so the membership and the use count
    # commit or roll back together.
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
