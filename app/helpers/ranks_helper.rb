# frozen_string_literal: true

# Copy for the rank screens. Screen-specific labels live in the screen's own
# helper, not in RedesignHelper.
module RanksHelper
  # The line under a rank's name on the teacher's ladder (30-lists.js:28).
  #
  # The mockup decides "starting rank" by array index, which mislabels a ladder
  # whose lowest rung sits at 30 — and it assumes that rung gives no discount.
  # Both are keyed off the record here instead.
  def rank_summary(rank)
    opening = rank.starting? ? 'Ranga startowa' : "Od #{rank.required_currency_value} zebranych"

    return "#{opening}, bez zniżki" if rank.discount.to_i.zero?

    "#{opening}, −#{rank.discount}% w sklepie"
  end

  # The same facts in the student's voice, as two sentences (30-sp.js:23).
  def rank_summary_sentences(rank)
    opening = rank.starting? ? 'Ranga startowa.' : "Od #{rank.required_currency_value} zebranych."

    return opening if rank.discount.to_i.zero?

    "#{opening} Daje −#{rank.discount}% w sklepie."
  end

  # One rung's terms on the form's drabinka (30-br.js:72). Shorter than the list
  # screens' line, and it has to survive a rank that starts at 0 AND gives a
  # discount, which the mockup's ladder cannot express.
  def rank_ladder_terms(rank)
    return "−#{rank.discount}% w sklepie" if rank.discount.to_i.positive?
    return 'Ranga startowa' if rank.starting?

    'Bez zniżki'
  end

  # What a rank is worth, for the preview card's rules line (30-br.js:71).
  def rank_reward_line(rank)
    line = "Wymagane: #{rank.required_currency_value.to_i} zebranych."

    return line if rank.discount.to_i.zero?

    "#{line} Daje −#{rank.discount}% w sklepie."
  end
end
