# frozen_string_literal: true

class CreateStoryGroupInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :story_group_invites do |t|
      t.references :story_group, null: false, foreign_key: true
      t.string :code
      t.datetime :expires_at
      t.integer :max_uses
      t.integer :uses, default: 0

      t.timestamps
    end
  end
end
