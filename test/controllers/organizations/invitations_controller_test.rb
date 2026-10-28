# frozen_string_literal: true

require 'test_helper'

class Organizations::InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = FactoryBot.create(:organization, max_members: 10)
    @admin = FactoryBot.create(:user, :organization_admin, organization: @organization)
    @invited = FactoryBot.create(:user, :student, organization: @organization, first_login: true)
  end

  test 'org admin resends a pending invitation with a fresh link' do
    old_token = @invited.create_login_token!
    sign_in @admin

    assert_enqueued_emails 1 do
      post organization_user_invitation_url(@organization, @invited)
    end

    assert_redirected_to organization_url(@organization)
    assert_not LoginToken.exists?(old_token.id)
    assert @invited.reload.login_token.expires_at > 6.days.from_now
  end

  test 'shows the resend button only for pending users' do
    FactoryBot.create(:user, :student, organization: @organization)
    sign_in @admin

    get organization_url(@organization)

    assert_select "form[action='#{organization_user_invitation_path(@organization, @invited)}']", count: 1
    assert_select "form[action$='/invitation']", count: 1
  end

  test 'cannot resend to someone who already accepted' do
    accepted = FactoryBot.create(:user, :student, organization: @organization)
    sign_in @admin

    assert_no_enqueued_emails do
      post organization_user_invitation_url(@organization, accepted)
    end

    assert_redirected_to root_url
  end

  test 'org admin cannot resend an admin invitation' do
    pending_admin = FactoryBot.create(:user, :organization_admin, organization: @organization, first_login: true)
    sign_in @admin

    assert_no_enqueued_emails do
      post organization_user_invitation_url(@organization, pending_admin)
    end
  end

  test 'org admin cannot resend in another organization' do
    other = FactoryBot.create(:organization, max_members: 10)
    foreign = FactoryBot.create(:user, :student, organization: other, first_login: true)
    sign_in @admin

    assert_no_enqueued_emails do
      post organization_user_invitation_url(other, foreign)
    end
  end

  test 'global admin resends an admin invitation' do
    pending_admin = FactoryBot.create(:user, :organization_admin, organization: @organization, first_login: true)
    sign_in FactoryBot.create(:user, :global_admin)

    assert_enqueued_emails 1 do
      post organization_user_invitation_url(@organization, pending_admin)
    end

    assert_redirected_to organization_url(@organization)
  end
end
