# frozen_string_literal: true

require 'test_helper'

class TeacherInvitationAcceptorTest < ActiveSupport::TestCase
  setup do
    @story_group = FactoryBot.create(:story_group, owner: FactoryBot.create(:user, :teacher))
    @invitation = FactoryBot.create(:teacher_invitation, story_group: @story_group, email: 'new@example.com')
  end

  test 'joins the invited groups as a teacher and removes the invitations' do
    user = FactoryBot.create(:user, :student, email: 'new@example.com')

    joined = TeacherInvitationAcceptor.new(user).call

    assert_equal [@story_group], joined
    assert_predicate user.reload, :teacher?
    assert_includes @story_group.teachers.reload, user
    assert_not TeacherInvitation.exists?(@invitation.id)
  end

  test 'does not demote an admin' do
    admin = FactoryBot.create(:user, :organization_admin, email: 'new@example.com')

    TeacherInvitationAcceptor.new(admin).call

    assert_predicate admin.reload, :organization_admin?
  end

  test 'does nothing for an address without invitations' do
    user = FactoryBot.create(:user, :student)

    assert_empty TeacherInvitationAcceptor.new(user).call
    assert_predicate user.reload, :student?
  end
end
