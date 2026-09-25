# frozen_string_literal: true

# Resolves an invite code typed into the join dialog, or carried by a QR link,
# into either a group you may join or the reason you may not.
#
# The read half of joining; AcceptInviteService is the write half. Split because
# the join flow asks this question twice — once to show step 2, once again
# inside the lock before actually creating the membership.
class InviteLookup
  # The mockup's own copy (design/mockup-src/js-expanded/30-sp.js:39). Each
  # case gets its own sentence because each has a different remedy.
  MESSAGES = {
    missing:   'Podaj kod zaproszenia.',
    not_found: 'Nie znaleźliśmy takiego kodu. Sprawdź go z prowadzącym.',
    expired:   'Ten kod wygasł. Poproś prowadzącego o nowy.',
    exhausted: 'Z tego kodu skorzystała już maksymalna liczba osób. ' \
               'Poproś prowadzącego o nowy.',
  }.freeze

  # `member_of` is deliberately not an error: already belonging to the group is
  # a dead end for the form but good news for the user, so the mockup shows it
  # as a hint with a link into the group rather than as a red field error.
  Result = Data.define(:invite, :reason, :member_of) do
    def initialize(invite: nil, reason: nil, member_of: nil)
      super
    end

    def ok? = reason.nil? && member_of.nil?
    def error = reason && MESSAGES[reason]
    def story_group = invite&.story_group
  end

  def initialize(user:, code:)
    @user = user
    @code = code
  end

  def call
    return Result.new(reason: :missing) if @code.to_s.strip.empty?

    invite = StoryGroupInvite.find_by_code(@code)
    return Result.new(reason: :not_found) unless invite

    reason = unusable_reason(invite)
    return Result.new(invite: invite, reason: reason) if reason

    member = membership_in(invite.story_group)
    return Result.new(invite: invite, member_of: invite.story_group) if member

    Result.new(invite: invite)
  end

  private

  # `usable?` folds both conditions into one boolean; the two have different
  # remedies, so they are asked separately here.
  def unusable_reason(invite)
    return :expired   unless invite.expire_time_condition
    return :exhausted unless invite.use_count_condition

    nil
  end

  def membership_in(story_group)
    story_group.student_memberships.find_by(user_id: @user.id)
  end
end
