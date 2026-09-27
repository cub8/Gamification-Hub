# frozen_string_literal: true

class InviteLookup
  MESSAGES = {
    missing:   'Podaj kod zaproszenia.',
    not_found: 'Nie znaleźliśmy takiego kodu. Sprawdź go z prowadzącym.',
    expired:   'Ten kod wygasł. Poproś prowadzącego o nowy.',
    exhausted: 'Z tego kodu skorzystała już maksymalna liczba osób. ' \
               'Poproś prowadzącego o nowy.',
  }.freeze

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

  def unusable_reason(invite)
    return :expired   unless invite.expire_time_condition
    return :exhausted unless invite.use_count_condition

    nil
  end

  def membership_in(story_group)
    story_group.student_memberships.find_by(user_id: @user.id)
  end
end
