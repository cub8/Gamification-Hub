# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'normalizes e-mail' do
    user = User.new(email: '   SIEMA@gmail.com   ')
    user.save!

    assert_equal 'siema@gmail.com', user.email
  end
end
