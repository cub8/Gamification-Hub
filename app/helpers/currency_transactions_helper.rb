# frozen_string_literal: true

# Screen-specific labels live in the screen's own helper, not in ApplicationHelper.
#
# The ledger is rendered by two screens — the student's own "Historia waluty"
# and the third tab of the teacher's student sheet — from one partial, so every
# piece of wording it needs is here rather than in either view.
module CurrencyTransactionsHelper
  # "Masz 19 do wydania i 34 zebrane łącznie." The number precedes the currency
  # name nowhere in this sentence on purpose: a group stores one nominative form
  # of its currency and Polish would want a different case here, so the sentence
  # simply does not name it. Same rule as ShopHelper#shop_balance_sentence.
  def ledger_balance_sentence(ledger)
    safe_join(['Masz ', tag.b(ledger.balance), ' do wydania i ', tag.b(ledger.total), ' zebrane łącznie.'])
  end

  # The teacher's version, which sits on one line beside the filters rather than
  # under a heading.
  def ledger_summary_sentence(ledger)
    safe_join(['Saldo: ', tag.b(ledger.balance), ', zebrane łącznie: ', tag.b(ledger.total), '.'])
  end

  # The filter chips. Links rather than buttons, because the app's .gh-fchip is
  # keyed on aria-current and because a filter that survives a refresh and can
  # be pasted to someone is worth a query parameter.
  def ledger_filter_chips(ledger, selected, path_for:)
    safe_join(CurrencyLedger::KINDS.map do |kind, label|
      current = kind == selected

      link_to path_for.call(kind), class: 'gh-fchip', 'aria-current': current.to_s do
        safe_join([label, tag.span(ledger.count_for(kind), class: 'gh-n')], ' ')
      end
    end)
  end

  # "Kupione 12.06, 10:21" — an entry's own timestamp. gh_when rather than
  # gh_stamp: a ledger is a feed, and "dziś 10:21" is what you want at the top
  # of one.
  def ledger_when(entry) = gh_when(entry.occurred_at)
end
