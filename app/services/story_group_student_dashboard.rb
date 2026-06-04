# frozen_string_literal: true

class StoryGroupStudentDashboard
  attr_reader :rank, :badges, :students_items

  def initialize(student:)
    @student = student
  end

  def load
    @rank           = @student.rank
    @badges         = @student.badges.with_attached_icon
    @students_items = @student.students_items
                              .includes(item: { image_attachment: :blob })
                              .order(created_at: :desc)
    self
  end
end
