# frozen_string_literal: true

require 'test_helper'

class SessionsHelperTest < ActionView::TestCase
  test 'see if example params for buttons are valid' do
    assert_difference 'User.count', 4 do
      student = User.create!(example_student_params)
      teacher = User.create!(example_teacher_params)
      organization_admin = User.create!(example_organization_admin_params)
      global_admin = User.create!(example_global_admin_params)

      assert_equal 'student', student.role
      assert_equal 'teacher', teacher.role
      assert_equal 'organization_admin', organization_admin.role
      assert_equal 'global_admin', global_admin.role
    end
  end
end
