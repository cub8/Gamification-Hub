# frozen_string_literal: true

require 'test_helper'

class LoginTokenTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = ::FactoryBot.create(:user)
  end

  test 'should setup expires_at on create to 5 minutes from now' do
    freeze_time do
      login_token = LoginToken.create!(user: @user)
      assert_equal 5.minutes.from_now, login_token.expires_at
    end
  end

  test 'should return false for expired? when token is not yet expired' do
    login_token = LoginToken.create!(user: @user)

    travel_to 4.minutes.from_now do
      assert_equal false, login_token.expired?
    end
  end

  test 'should return true for expired? when token is expired' do
    login_token = LoginToken.create!(user: @user)

    travel_to 6.minutes.from_now do
      assert_equal true, login_token.expired?
    end
  end
end
