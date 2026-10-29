# frozen_string_literal: true

module RanksHelper
  def rank_summary(rank)
    opening = rank.starting? ? t('ranks.helpers.starting') : t('ranks.helpers.from', min: rank.required_currency_value)

    return t('ranks.helpers.summary_no_discount', opening: opening) if rank.discount.to_i.zero?

    t('ranks.helpers.summary_discount', opening: opening, discount: rank.discount)
  end

  def rank_summary_sentences(rank)
    opening = if rank.starting?
                t('ranks.helpers.starting_sentence')
              else
                t('ranks.helpers.from_sentence', min: rank.required_currency_value)
              end

    return opening if rank.discount.to_i.zero?

    "#{opening} #{t('ranks.helpers.gives_discount', discount: rank.discount)}"
  end

  def rank_ladder_terms(rank)
    return t('ranks.helpers.discount', discount: rank.discount) if rank.discount.to_i.positive?
    return t('ranks.helpers.starting') if rank.starting?

    t('ranks.helpers.no_discount')
  end

  def rank_reward_line(rank)
    line = t('ranks.helpers.required', min: rank.required_currency_value.to_i)

    return line if rank.discount.to_i.zero?

    "#{line} #{t('ranks.helpers.gives_discount', discount: rank.discount)}"
  end
end
