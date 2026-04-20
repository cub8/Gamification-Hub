# frozen_string_literal: true

class CreateStudentsActivityGroupCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :students_activity_group_categories do |t|
      t.references :student, null: false, foreign_key: { to_table: :story_group_students }
      t.references :activity_group_category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :students_activity_group_categories,
              %i[student_id activity_group_category_id],
              unique: true,
              name:   'index_student_activity_group_categories_unique'
  end
end
