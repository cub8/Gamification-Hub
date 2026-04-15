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
  end
end

# rubocop:enable Style/OneClassPerFile
