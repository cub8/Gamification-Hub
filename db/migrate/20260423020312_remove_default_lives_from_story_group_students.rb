# frozen_string_literal: true

class RemoveDefaultLivesFromStoryGroupStudents < ActiveRecord::Migration[8.1]
  def change
    change_column_default :story_group_students, :lives, from: 3, to: nil
  end
end
