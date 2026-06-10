# frozen_string_literal: true

module ApplicationHelper
  def transaction_description(transaction, story_group)
    student_name = transaction.student.full_name
    case transaction.kind
    when 'purchase'
      item_name = transaction.transactionable&.name || 'przedmiot'
      "#{student_name} zakupił #{item_name} za #{transaction.amount.abs} #{story_group.currency_name}"
    when 'reward'
      category_name = transaction.transactionable&.didactic_description || 'aktywność'
      "#{student_name} zdobył nagrodę za: #{category_name}"
    when 'adjustment'
      sign = transaction.amount >= 0 ? '+' : ''
      adjuster = transaction.granted_by_user&.full_name || 'nauczyciel'
      "#{adjuster} skorygował walutę #{student_name} (#{sign}#{transaction.amount})"
    end
  end
end
