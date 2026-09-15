# frozen_string_literal: true

class AddGlyphAndSoftDeleteToBadges < ActiveRecord::Migration[8.1]
  def change
    # Which preset a badge uses, as a key into Redesign::Glyphs. Same contract
    # as ranks (20260914090000): the artwork lives in app/assets/images and is
    # never copied into the database, and this column together with the
    # attachment says which of the two is the art:
    #
    #   NULL + attachment -> the upload
    #   key  + attachment -> the preset, upload kept so you can switch back
    #   key  + no upload  -> the preset
    add_column :badges, :icon_glyph, :string

    # Soft delete (DECISIONS.md:28, :54). A deleted badge leaves the lists, the
    # pickers and the award dialog, but every students_badges row pointing at it
    # stays valid — the student keeps what they earned. Badge has NO
    # default_scope for this: the join model and the discount services must go
    # on resolving a deleted badge, so `kept` is applied at the list and picker
    # call sites instead.
    add_column :badges, :deleted_at, :datetime
    add_index :badges, %i[story_group_id deleted_at]
  end
end
