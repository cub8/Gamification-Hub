# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :usos_id
      t.string :email
      t.string :full_name
      t.string :university_number
      t.string :university_name
      t.integer :role, default: 1
      t.boolean :first_login, default: true

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, %i[usos_id university_name], unique: true
  end
end
