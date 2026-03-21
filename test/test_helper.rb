# frozen_string_literal: true

# rubocop:disable Style/OneClassPerFile

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

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
      get auth_callback_path('development'), params: {
        email: user.email,
      }
    end

    def sign_out
      delete logout_path
    end
  end
end

# rubocop:enable Style/OneClassPerFile
