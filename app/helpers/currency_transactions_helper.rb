# frozen_string_literal: true

module CurrencyTransactionsHelper
  def transaction_badge_class(transaction)
    {
      'reward'     => 'bg-primary',
      'adjustment' => 'bg-secondary',
      'purchase'   => 'bg-info',
    }[transaction.kind] || 'bg-secondary'
  end

  def transaction_source(transaction)

    if transaction.kind == 'adjustment'
      transaction.granted_by_user&.full_name

    elsif transaction.transactionable.is_a?(ActivityGroupCategory)
      transaction.transactionable.didactic_description

    elsif transaction.transactionable.is_a?(Item)
      transaction.transactionable.name

    else
      transaction.transactionable_type
    end
  end
end
