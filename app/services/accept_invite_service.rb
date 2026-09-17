# frozen_string_literal: true

# Creates the membership behind an invite code.
#
# The write half of joining; InviteLookup is the read half. The code is checked
# again here, inside the row lock, because the check that rendered step 2 is a
# few seconds stale by the time the form comes back and the last seat may be
# gone.
class AcceptInviteService
  Result = Struct.new(:success, :membership, :reason, :story_group) do
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
    # Not normalised here any more: StoryGroupStudent#normalise_nickname owns
    # the blank-means-NULL rule, because the settings screen writes this column
    # too and the partial unique index depends on it.
    @nickname = nickname
  end

  def call
    result = Result.new(success: false, story_group: @story_group)

    # with_lock is itself a transaction, so the membership and the use count
    # commit or roll back together.
    @invite.with_lock do
      recheck = InviteLookup.new(user: @current_user, code: @invite.code).call

      if recheck.ok?
        save_membership(result)
      else
        result.reason = recheck.reason || :already_member
      end
    end

    result
  end

  private

  def save_membership(result)
    membership = @story_group.student_memberships.build(user: @current_user, nickname: @nickname)
    result.membership = membership

    if membership.save
      @invite.use!
      result.success = true
    else
      result.reason = :invalid
    end
  end
end
