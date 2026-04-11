# frozen_string_literal: true

module StoryGroupTeachersHelper

  def teachers(user)
    if user.global_admin?
      User.where(role: %i[teacher organization_admin global_admin])
    else
      User.where(role: %i[teacher organization_admin global_admin])
          .where(university_name: user.university_name)
    end
  end

  def teacher_map(user)
    teachers(user).map do |u|
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
