# frozen_string_literal: true

require 'test_helper'

class TeacherInvitationsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @organization = FactoryBot.create(:organization, max_members: 10)
    @owner = FactoryBot.create(:user, :teacher, organization: @organization)
    @story_group = FactoryBot.create(:story_group, owner: @owner)
  end

  test 'the owner invites an unknown address and an e-mail goes out' do
    sign_in @owner

    assert_enqueued_emails 1 do
      assert_difference('TeacherInvitation.count') do
        post invite_story_group_teachers_url(@story_group),
             params: { teacher_invitation: { email: 'new@example.com' } }
      end
    end

    assert_turbo_redirected_to story_group_teachers_url(@story_group)

    get story_group_teachers_url(@story_group)
    assert_select '.gh-teacher-invitations b', 'new@example.com'
  end

  test 'a refused invitation re-renders the dialog with the error' do
    FactoryBot.create(:user, :student, email: 'student@example.com')
    sign_in @owner

    post invite_story_group_teachers_url(@story_group),
         params: { teacher_invitation: { email: 'student@example.com' } }

    assert_response :unprocessable_content
    assert_select '#gh-teacher-invite-error', /konto studenta/
  end

  test 'a supporting teacher can not invite' do
    helper = FactoryBot.create(:user, :teacher)
    FactoryBot.create(:story_group_teacher, story_group: @story_group, user: helper)
    sign_in helper

    assert_no_difference('TeacherInvitation.count') do
      post invite_story_group_teachers_url(@story_group),
           params: { teacher_invitation: { email: 'new@example.com' } }
    end
  end

  test 'the owner cancels a pending invitation' do
    invitation = FactoryBot.create(:teacher_invitation, story_group: @story_group, invited_by: @owner)
    sign_in @owner

    delete story_group_teacher_invitation_url(@story_group, invitation)

    assert_redirected_to story_group_teachers_url(@story_group)
    assert_not TeacherInvitation.exists?(invitation.id)
  end

  test 'the e-mailed link creates the account, joins the group and asks for a name' do
    invitation = FactoryBot.create(:teacher_invitation, story_group: @story_group, invited_by: @owner,
                                                        email: 'new@example.com',)

    assert_difference('User.count') do
      get auth_teacher_invitation_url(token: invitation.accept_token)
    end

    user = User.find_by!(email: 'new@example.com')
    assert_predicate user, :teacher?
    assert_equal @organization, user.organization
    assert_includes @story_group.teachers.reload, user
    assert_redirected_to story_group_url(@story_group)

    follow_redirect!
    assert_redirected_to edit_account_setup_url
  end

  test 'a used or forged link is refused' do
    get auth_teacher_invitation_url(token: 'forged')

    assert_redirected_to login_url
  end

  test 'typing an invited address on the login page sends a login link' do
    FactoryBot.create(:teacher_invitation, story_group: @story_group, invited_by: @owner, email: 'new@example.com')

    assert_enqueued_emails 1 do
      post auth_passwordless_url, params: { email: 'new@example.com' }
    end

    assert_predicate User.find_by!(email: 'new@example.com'), :teacher?
  end

  test 'any sign-in applies a pending invitation' do
    user = FactoryBot.create(:user, :student)
    FactoryBot.create(:teacher_invitation, story_group: @story_group, invited_by: @owner, email: user.email)

    sign_in user

    assert_redirected_to story_group_url(@story_group)
    assert_includes @story_group.teachers.reload, user
  end
end
