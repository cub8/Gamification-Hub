# frozen_string_literal: true

# rubocop:disable Style/OneClassPerFile

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)
  end
end

module ActionDispatch
  class IntegrationTest
    def sign_in(user)
      login_token = user.create_login_token!
      get auth_passwordless_verify_path(token: login_token.raw_token)
    end

    def sign_out
      delete logout_path
    end

    def assert_turbo_redirected_to(expected_url)
      assert_response :success
      assert_equal 'text/vnd.turbo-stream.html', response.media_type

      if response.body =~ /turbo-stream action="redirect" target="([^"]+)"/
        actual_url = ::Regexp.last_match(1)

        expected_path = URI.parse(expected_url).path || expected_url
        actual_path   = URI.parse(actual_url).path

        assert_equal expected_path, actual_path,
                     "Expected to be Turbo-redirected to <#{expected_path}> but was redirected to <#{actual_path}>"
      else
        flunk 'Expected a Turbo Stream redirect, but none was found in the response body.'
      end
    end
  end
end

# rubocop:enable Style/OneClassPerFile
