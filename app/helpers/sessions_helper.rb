# frozen_string_literal: true

module SessionsHelper
  def development_login_buttons

  end

  def development_auth_callback_path
    auth_callback_path('development')
  end

  def example_student_params
    {
      full_name:         'Student User',
      email:             'student@example.com',
      role:              'student',
      university_name:   'Example University',
      university_number: '123456',
    }
  end

  def example_university_teacher_params
    {
      full_name:         'Teacher User',
      email:             'teacher@example.com',
      role:              'university_teacher',
      university_name:   'Example University',
      university_number: '987654',
    }
  end

  def example_university_admin_params
    {
      full_name:         'University Admin',
      email:             'uniadmin@example.com',
      role:              'university_admin',
      university_name:   'Example University',
      university_number: '888111',
    }
  end

  def example_global_admin_params
    {
      full_name: 'Global Admin',
      email:     'globaladmin@example.com',
      role:      'global_admin',
    }
  end
end
