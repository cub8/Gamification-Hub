# frozen_string_literal: true

class CreateLoginTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :login_tokens do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :token_digest
      t.datetime :expires_at

      t.timestamps
    end

    # add_index :login_tokens, :token_digest, unique: true
  end
end
