# frozen_string_literal: true

class AddSheetLifecycleToActivityGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :activity_group_categories, :hidden, :boolean, default: false, null: false

    add_column :activity_groups,          :deleted_at, :datetime
    add_column :activity_group_templates, :deleted_at, :datetime
    add_index  :activity_groups,          %i[story_group_id deleted_at]
    add_index  :activity_group_templates, %i[story_group_id deleted_at]

    add_column :activity_groups, :columns_modified_at, :datetime

    add_reference :activity_group_categories, :source_category,
                  null: true, index: true,
                  foreign_key: { to_table: :activity_group_template_categories, on_delete: :nullify }
  end
end
