# frozen_string_literal: true

require 'test_helper'

class Auth::SignInTest < ActiveSupport::TestCase
  class Host
    include Auth::SignIn

    def home_path = '/home'

    def resolve(path) = after_login_path(path)
  end

  test 'accepts local paths' do
    assert_equal '/join/abc?x=1', Host.new.resolve('/join/abc?x=1')
  end

  test 'rejects external and malformed targets' do
    ['//evil.com', 'https://evil.com', 'javascript:alert(1)', '', nil].each do |path|
      assert_equal '/home', Host.new.resolve(path), "expected #{path.inspect} to fall back to home"
    end
  end
end
