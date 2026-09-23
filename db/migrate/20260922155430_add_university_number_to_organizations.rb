class AddUniversityNumberToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :university_number, :string
    add_index :organizations, :university_number, unique: true
  end
end
