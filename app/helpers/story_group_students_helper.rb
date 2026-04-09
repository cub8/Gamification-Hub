# frozen_string_literal: true

module StoryGroupStudentsHelper

  def student_map
    User.all.map do |u|
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
