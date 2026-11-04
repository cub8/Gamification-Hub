# frozen_string_literal: true

class TeacherInvitationAcceptor
  def initialize(user)
    @user = user
  end

  def call
    return [] if @user.email.blank?

    invitations = TeacherInvitation.where(email: @user.email).includes(:story_group).to_a
    return [] if invitations.empty?

    User.transaction do
      @user.update!(role: :teacher) if @user.student?
      invitations.filter_map { |invitation| accept(invitation) }
    end
  end

  private

  def accept(invitation)
    story_group = invitation.story_group
    invitation.destroy!

    return if story_group.owner_id == @user.id
    return if story_group.teacher_memberships.exists?(user: @user)

    story_group.teacher_memberships.create!(user: @user)
    story_group
  end
end
