# frozen_string_literal: true

class AddUniqueIndexToOrganizationsName < ActiveRecord::Migration[8.1]
  def change
    add_index :organizations, :name, unique: true
  end
end
