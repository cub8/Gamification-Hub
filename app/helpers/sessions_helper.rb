# frozen_string_literal: true

module SessionsHelper
  def development_login_buttons
    return if Rails.env.production?

    content_tag(:div) do
      base_development_login_button('Login as STUDENT', example_student_params) +
        base_development_login_button('Login as UNIVERSITY TEACHER', example_university_teacher_params) +
        base_development_login_button('Login as UNIVERSITY ADMIN', example_university_admin_params) +
        base_development_login_button('Login as GLOBAL ADMIN', example_global_admin_params)
    end
  end

  def base_development_login_button(text, params)
    button_to text, development_auth_callback_path, method: :get, params: params, data: { turbo: false }
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
