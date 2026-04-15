# frozen_string_literal: true

module StudentsHelper

  def students(user)
    if user.global_admin?
      User.all
    else
      User.where(university_name: user.university_name)
    end
  end

  def student_map(user)
    students(user).map do |u|
      {
        value: u.id,
        text:  u.email,
        name:  u.full_name,
        email: u.email,
        id:    u.university_number,
      }
    end
  end
end
