# frozen_string_literal: true

class AddGlyphAndSoftDeleteToItems < ActiveRecord::Migration[8.1]
  def up
    # Which preset an item uses, as a key into Redesign::Glyphs. Same contract
    # as ranks (20260914090000) and badges (20260914140000): the artwork lives
    # in app/assets/images and is never copied into the database, and this
    # column together with the attachment says which of the two is the art:
    #
    #   NULL + attachment -> the upload
    #   key  + attachment -> the preset, upload kept so you can switch back
    #   key  + no upload  -> the preset
    add_column :items, :icon_glyph, :string

    # Soft delete (DECISIONS.md:28). A deleted item leaves the shop, the teacher
    # list and the pickers, but every students_items row pointing at it stays
    # valid — "Kupione egzemplarze zostaja u studentow". No default_scope: the
    # purchase history must go on resolving a deleted item, so `kept` is applied
    # at the list, shop and picker call sites instead.
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

  # Item's artwork was `has_one_attached :image` while every other entity uses
  # `:icon` — and the shared image field (shared/redesign/_image_field) is
  # written against `record.icon` / `record.icon_glyph`. ActiveStorage keys an
  # attachment by its `name` column, so renaming the association is this one
  # UPDATE: no blob is copied, moved or re-keyed.
  def rename_attachment(from, to)
    execute(<<~SQL.squish)
      UPDATE active_storage_attachments
         SET name = #{connection.quote(to)}
       WHERE record_type = 'Item'
         AND name = #{connection.quote(from)}
    SQL
  end
end
