# frozen_string_literal: true

class AddUsosToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :usos, :boolean, default: false, null: false
    add_index :organizations, :usos, unique: true, where: 'usos'
  end
end
