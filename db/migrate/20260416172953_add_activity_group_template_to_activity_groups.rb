class AddActivityGroupTemplateToActivityGroups < ActiveRecord::Migration[8.1]
  def change
    add_reference :activity_groups, :activity_group_template, null: true, foreign_key: true
  end
end
