# frozen_string_literal: true

require 'test_helper'

class LoginTokenTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = ::FactoryBot.create(:user)
  end

  test 'should setup expires_at on create to EXPIRES_IN from now' do
    freeze_time do
      login_token = LoginToken.create!(user: @user)
      assert_equal LoginToken::EXPIRES_IN.from_now, login_token.expires_at
    end
  end

  test 'should return false for expired? when token is not yet expired' do
    login_token = LoginToken.create!(user: @user)

    travel_to (LoginToken::EXPIRES_IN - 1.minute).from_now do
      assert_equal false, login_token.expired?
    end
  end

  test 'should return true for expired? when token is expired' do
    login_token = LoginToken.create!(user: @user)

    travel_to (1.minute + LoginToken::EXPIRES_IN).from_now do
      assert_equal true, login_token.expired?
    end
  end
end
