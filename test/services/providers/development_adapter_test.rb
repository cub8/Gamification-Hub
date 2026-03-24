# frozen_string_literal: true

require 'test_helper'

module Providers
  class DevelopmentAdapterTest < ActiveSupport::TestCase
    test 'build auth params' do
      auth = {
        email:             'jan.nowak@gmail.com',
        usos_id:           '123456',
        university_number: '987654',
        university_name:   'Example University',
        full_name:         'Jan Nowak',
        role:              'student',
      }

      provider = DevelopmentAdapter.new(auth)
      user_params = provider.user_params

      assert_equal 'Jan Nowak', user_params[:full_name]
      assert_equal 'jan.nowak@gmail.com', user_params[:email]
      assert_equal 'Example University', user_params[:university_name]
      assert_equal '987654', user_params[:university_number]
      assert_equal '123456', user_params[:usos_id]
      assert_equal 'student', user_params[:role]
    end

    test 'raise an error if auth is nil' do
      assert_raises InvalidAuthError do
        DevelopmentAdapter.new(nil)
      end
    end
  end
end
