# frozen_string_literal: true

module CurrencyTransactionsHelper
  def transaction_kind_badge(transaction)
    badge_class = case transaction.kind
                  when 'reward'   then 'bg-primary'
                  when 'purchase' then 'bg-info'
                  else                 'bg-secondary'
                  end
    content_tag(:span, transaction.kind.capitalize, class: "badge #{badge_class}")
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
