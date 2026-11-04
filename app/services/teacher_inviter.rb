# frozen_string_literal: true

class TeacherInviter
  Result = Data.define(:status, :email, :user, :invitation, :error) do
    def initialize(status:, email:, user: nil, invitation: nil, error: nil)
      super
    end

    def ok? = error.nil?
  end

  STAFF_ROLES = %w[teacher organization_admin global_admin].freeze

  def initialize(story_group:, inviter:, email:)
    @story_group = story_group
    @inviter = inviter
    @email = TeacherInvitation.normalize_value_for(:email, email.to_s)
  end

  def call
    user = User.find_by(email: @email) if @email.present?
    user ? add_existing(user) : invite
  end

  private

  def add_existing(user)
    return failure(:in_group) if in_group?(user)
    return failure(:student_account) unless STAFF_ROLES.include?(user.role)

    @story_group.teacher_memberships.create!(user: user)
    Result.new(status: :added, email: @email, user: user)
  end

  def invite
    invitation = @story_group.teacher_invitations.find_or_initialize_by(email: @email)
    status = invitation.persisted? ? :resent : :invited
    invitation.invited_by = @inviter

    return Result.new(status: :invalid, email: @email, error: invitation.errors[:email].first) unless invitation.save

    Result.new(status: status, email: @email, invitation: invitation)
  end

  def in_group?(user)
    @story_group.owner_id == user.id || @story_group.teacher_memberships.exists?(user: user)
  end

  def failure(key)
    Result.new(status: key, email: @email, error: I18n.t("teachers.invite.errors.#{key}"))
  end
end
