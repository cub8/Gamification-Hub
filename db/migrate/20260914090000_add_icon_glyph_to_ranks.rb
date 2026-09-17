# frozen_string_literal: true

class AddIconGlyphToRanks < ActiveRecord::Migration[8.1]
  def change
    # Which preset a rank uses, as a key into Redesign::Glyphs — the artwork
    # itself lives in app/assets/images/redesign/glyphs and is never copied into
    # the database. NULL means "use the uploaded icon instead", so the two
    # together say which of the two is the art:
    #
    #   NULL + attachment -> the upload
    #   key  + attachment -> the preset, upload kept so you can switch back
    #   key  + no upload  -> the preset
    add_column :ranks, :icon_glyph, :string

    # Two rungs at the same threshold make "which rank do I hold" arbitrary.
    # The model reports the clash with the other rank's name; this is the
    # backstop, and it is what keeps an edit MOVING a rung rather than landing
    # it on top of another one.
    add_index :ranks, %i[story_group_id required_currency_value], unique: true,
                                                                  name:   'index_ranks_on_group_and_threshold'
  end
end
