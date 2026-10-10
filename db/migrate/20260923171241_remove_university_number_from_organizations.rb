# frozen_string_literal: true

class RemoveUniversityNumberFromOrganizations < ActiveRecord::Migration[8.1]
  def change
    remove_column :organizations, :university_number, :string
  end
end
