# frozen_string_literal: true

class AddGlyphAndSoftDeleteToItems < ActiveRecord::Migration[8.1]
  def up
    add_column :items, :icon_glyph, :string

    add_column :items, :deleted_at, :datetime
    add_index :items, %i[story_group_id deleted_at]

    rename_attachment 'image', 'icon'
  end

  def down
    rename_attachment 'icon', 'image'

    remove_index :items, %i[story_group_id deleted_at]
    remove_column :items, :deleted_at
    remove_column :items, :icon_glyph
  end

  private

  def rename_attachment(from, to)
    execute(<<~SQL.squish)
      UPDATE active_storage_attachments
         SET name = #{connection.quote(to)}
       WHERE record_type = 'Item'
         AND name = #{connection.quote(from)}
    SQL
  end
end
