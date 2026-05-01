# frozen_string_literal: true

class MakeTransactionableOptionalInCurrencyTransactions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :currency_transactions, :transactionable_id,   true
    change_column_null :currency_transactions, :transactionable_type, true
  end
end
