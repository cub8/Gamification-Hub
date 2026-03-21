# frozen_string_literal: true

require 'test_helper'

module Providers
  class UsosAdapterTest < ActiveSupport::TestCase
    test 'build auth params' do
      user_data = {
        'id'             => '123456',
        'first_name'     => 'Jan',
        'last_name'      => 'Nowak',
        'email'          => 'jan.nowak@gmail.com',
        'student_number' => '987654',
      }

      UsosAdapter
        .any_instance
        .stubs(:extract_user_data_from_usos)
        .returns(user_data)

      auth = {
        'token'  => '123456',
        'secret' => 'abcdef',
      }

      provider = UsosAdapter.new(auth)
      user_params = provider.user_params

      assert_equal 'Jan Nowak', user_params[:full_name]
      assert_equal 'jan.nowak@gmail.com', user_params[:email]
      assert_equal 'Uniwersytet im. Adama Mickiewicza', user_params[:university_name]
      assert_equal '987654', user_params[:university_number]
      assert_equal '123456', user_params[:usos_id]
      assert_equal 'student', user_params[:role]
    end

    test 'raise an error if auth is nil' do
      assert_raises InvalidAuthError do
        UsosAdapter.new(nil)
      end
    end
  end
end
