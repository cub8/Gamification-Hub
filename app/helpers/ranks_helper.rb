# frozen_string_literal: true

module RanksHelper
  def rank_summary(rank)
    opening = rank.starting? ? 'Ranga startowa' : "Od #{rank.required_currency_value} zebranych"

    return "#{opening}, bez zniżki" if rank.discount.to_i.zero?

    "#{opening}, −#{rank.discount}% w sklepie"
  end

  def rank_summary_sentences(rank)
    opening = rank.starting? ? 'Ranga startowa.' : "Od #{rank.required_currency_value} zebranych."

    return opening if rank.discount.to_i.zero?

    "#{opening} Daje −#{rank.discount}% w sklepie."
  end

  def rank_ladder_terms(rank)
    return "−#{rank.discount}% w sklepie" if rank.discount.to_i.positive?
    return 'Ranga startowa' if rank.starting?

    'Bez zniżki'
  end

  def rank_reward_line(rank)
    line = "Wymagane: #{rank.required_currency_value.to_i} zebranych."

    return line if rank.discount.to_i.zero?

    "#{line} Daje −#{rank.discount}% w sklepie."
  end
end
