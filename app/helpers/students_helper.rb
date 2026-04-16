# frozen_string_literal: true

module StudentsHelper

  def student_map(students)
    students.map do |u|
      {
        value:             u.id,
        text:              u.email,
        name:              u.full_name,
        email:             u.email,
        university_number: u.university_number,
      }
    end
  end
end
