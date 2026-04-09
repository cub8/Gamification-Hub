# frozen_string_literal: true

module StoryGroupTeachersHelper

  def teachers
    User.where(role: %i[teacher organization_admin global_admin])
  end

  def teacher_map
    teachers.map do |u|
      {
        value: u.id,
        text:  u.email,
        name:  u.full_name,
        email: u.email,
        id:    u.usos_id,
      }
    end
  end
end
