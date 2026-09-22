# frozen_string_literal: true

class AddSheetLifecycleToActivityGroups < ActiveRecord::Migration[8.1]
  def change
    # DECISIONS.md:31 — a column that has already paid out cannot be removed,
    # only hidden. Hiding takes it out of the grading table and out of the
    # "do N marchewek za arkusz" ceiling; the awards it already made stay.
    add_column :activity_group_categories, :hidden, :boolean, default: false, null: false

    # DECISIONS.md:54 — soft delete everywhere. Deleting a sheet leaves the
    # currency it granted in the students' history, and deleting a template
    # leaves the sheets made from it alone. Only deleting the story group
    # deletes anything for real, which is why the `dependent: :destroy` chain
    # from StoryGroup stays in place.
    add_column :activity_groups,          :deleted_at, :datetime
    add_column :activity_group_templates, :deleted_at, :datetime
    add_index  :activity_groups,          %i[story_group_id deleted_at]
    add_index  :activity_group_templates, %i[story_group_id deleted_at]

    # The "Zmienione kolumny" tag on the index. It cannot be derived by
    # diffing a sheet against its template, because DECISIONS.md:30 says a
    # template edit must not reach back into sheets that already exist — so a
    # sheet nobody touched would start reporting itself as modified the moment
    # the template changed. This records the only thing the tag actually means:
    # someone edited THIS sheet's columns.
    add_column :activity_groups, :columns_modified_at, :datetime

    # The "Tylko w tym arkuszu" tag. A sheet column copied from the template
    # points back at its source; a column added later in sheet settings points
    # nowhere. Nullify rather than cascade: if the template column is gone, the
    # sheet column is genuinely sheet-only now, and it must survive to keep the
    # awards hanging off it.
    add_reference :activity_group_categories, :source_category,
                  null: true, index: true,
                  foreign_key: { to_table: :activity_group_template_categories, on_delete: :nullify }
  end
end
