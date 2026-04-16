# frozen_string_literal: true

module TeachersHelper

  def teacher_map(teachers)
    teachers.map do |u|
      {
        value: u.id,
        text:  u.email,
        name:  u.full_name,
        email: u.email,
      }
    end
  end
end
