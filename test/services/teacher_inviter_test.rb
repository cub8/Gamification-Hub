# frozen_string_literal: true

require 'test_helper'

class TeacherInviterTest < ActiveSupport::TestCase
  setup do
    @owner = FactoryBot.create(:user, :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner)
  end

  test 'adds an existing teacher account straight away' do
    teacher = FactoryBot.create(:user, :teacher, email: 'anna@example.com')

    result = invite(' Anna@Example.com ')

    assert_equal :added, result.status
    assert_includes @story_group.teachers.reload, teacher
    assert_empty @story_group.teacher_invitations
  end

  test 'stores an invitation for an unknown address' do
    result = invite('new.teacher@example.com')

    assert_equal :invited, result.status
    assert_equal 'new.teacher@example.com', result.invitation.email
    assert_equal @owner, result.invitation.invited_by
  end

  test 'inviting the same address again resends instead of duplicating' do
    invite('new.teacher@example.com')

    assert_no_difference('TeacherInvitation.count') do
      assert_equal :resent, invite('NEW.teacher@example.com').status
    end
  end

  test 'refuses an existing student account' do
    FactoryBot.create(:user, :student, email: 'student@example.com')

    result = invite('student@example.com')

    assert_not result.ok?
    assert_equal :student_account, result.status
    assert_empty @story_group.teachers
  end

  test 'refuses someone already in the group' do
    assert_equal :in_group, invite(@owner.email).status
  end

  test 'refuses a malformed address' do
    result = invite('not-an-email')

    assert_not result.ok?
    assert_equal 'To nie wygląda na adres e-mail.', result.error
  end

  private

  def invite(email)
    TeacherInviter.new(story_group: @story_group, inviter: @owner, email: email).call
  end
end
