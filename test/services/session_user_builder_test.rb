# frozen_string_literal: true

require 'test_helper'

class SessionUserBuilderTest < ActiveSupport::TestCase
  setup do
    @provider = Providers::DevelopmentAdapter.new(
      {
        full_name:         'Jan Nowak',
        email:             'jan.nowak@gmail.com',
        role:              'student',
        university_name:   'Example university',
        university_number: '123456',
        usos_id:           '123456',
      },
    )
  end

  test 'create new user if no user in database' do
    assert_difference 'User.count', 1 do
      user = SessionUserBuilder.new(@provider).build

      assert_equal 'jan.nowak@gmail.com', user.email
    end
  end

  test 'do not create new user if user exists' do
    original_user = FactoryBot.create(:user, email: 'jan.nowak@gmail.com')

    assert_no_difference 'User.count' do
      user = SessionUserBuilder.new(@provider).build
      assert_equal original_user.id, user.id
    end
  end

  test 'update user if user exists, but first_login is true' do
    user = FactoryBot.create(:user, first_login: true, email: nil, usos_id: '123456', university_name: 'Example university')
    SessionUserBuilder.new(@provider).build

    assert_equal 'jan.nowak@gmail.com', user.reload.email
  end

  test 'raise an error if no usos_id or email in provider' do
    provider = Providers::DevelopmentAdapter.new(
      {
        full_name:       'Jan Nowak',
        role:            'student',
        university_name: 'Example university',
      },
    )

    assert_raises Providers::InvalidAuthError do
      SessionUserBuilder.new(provider).build
    end
  end
end
