# frozen_string_literal: true

class CreateCurrencyTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :currency_transactions do |t|
      t.references :student,         null: false, foreign_key: { to_table: :story_group_students }
      t.integer    :amount,          null: false
      t.references :granted_by_user, null: true,  foreign_key: { to_table: :users }
      t.references :transactionable, null: false, polymorphic: true
      t.integer    :kind,            null: false

      t.timestamps
    end
  end
end
