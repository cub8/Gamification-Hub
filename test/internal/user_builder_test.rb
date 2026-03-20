# frozen_string_literal: true

require 'test_helper'

class UserBuilderTest < ActiveSupport::TestCase
  test 'should create new user for development if no user exists' do
    auth = {
      full_name:         'Jan Nowak',
      email:             'jan.nowak@st.amu.edu.pl',
      university_name:   'Example university',
      university_number: '123456',
      role:              'student',
    }

    assert_difference 'User.count', 1 do
      builder = UserBuilder.new(auth, 'development')
      user = builder.build

      assert_equal 'Jan Nowak', user.full_name
      assert_equal 'jan.nowak@st.amu.edu.pl', user.email
      assert_equal 'Example university', user.university_name
      assert_equal '123456', user.university_number
      assert_equal 'student', user.role
      assert_nil user.usos_id
    end
  end

  test 'should not create new user for development if no user exists' do
    FactoryBot.create(:user, :student)

    auth = {
      full_name:         'Jan Nowak',
      email:             'jan.nowak@st.amu.edu.pl',
      university_name:   'Example university',
      university_number: '123456',
      role:              'student',
    }

    assert_no_difference 'User.count' do
      builder = UserBuilder.new(auth, 'development')
      user = builder.build

      assert_equal 'Jan Nowak', user.full_name
      assert_equal 'jan.nowak@st.amu.edu.pl', user.email
      assert_equal 'Example university', user.university_name
      assert_equal '123456', user.university_number
      assert_equal 'student', user.role
      assert_equal '123456', user.usos_id
    end
  end

  test 'raise InvalidAuthError if auth is nil' do
    assert_raises UserBuilder::InvalidAuthError do
      UserBuilder.new(nil, 'development')
    end
  end
end
