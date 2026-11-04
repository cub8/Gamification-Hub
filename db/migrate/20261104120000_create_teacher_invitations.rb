# frozen_string_literal: true

class CreateTeacherInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :teacher_invitations do |t|
      t.references :story_group, null: false, foreign_key: true, index: false
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false

      t.timestamps
    end

    add_index :teacher_invitations, %i[story_group_id email], unique: true
    add_index :teacher_invitations, :email
  end
end
