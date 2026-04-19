# frozen_string_literal: true

class CreateStudentsBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :students_badges do |t|
      t.references :story_group_student, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true

      t.timestamps
    end
  end
end
