# frozen_string_literal: true

module ShopHelper
  # "Masz 120 do wydania."
  #
  # The number comes before "do wydania" so the currency's name never has to be
  # declined: a group holds one nominative form ("marchewki") and Polish wants
  # the genitive here. ranks/_teacher_ladder.html.haml:8 makes the same dodge.
  def shop_balance_sentence(balance)
    t('shop.helpers.balance_html', balance: tag.b(balance))
  end

  # "Twoje odznaki Mechanik i Nawigator obniżają ceny niektórych przedmiotów."
  # Nil when the student holds none that discount anything, which is the state
  # every student starts in.
  def shop_discount_sentence(badges)
    return if badges.empty?

    names = badges.map { |badge| tag.b(badge.name) }

    t('shop.helpers.discount_badges_html', count: badges.size, badges: gh_and_list_html(names))
  end

  # gh_and_list, but for parts that are already markup: Array#join would hand
  # safe_join a plain String and every <b> would come back escaped. The
  # connectors are rails-i18n's, the same ones Array#to_sentence uses.
  def gh_and_list_html(parts)
    return parts.first if parts.size < 2
    return safe_join(parts, t('support.array.two_words_connector')) if parts.size == 2

    safe_join([safe_join(parts[0..-2], t('support.array.words_connector')), parts.last],
              t('support.array.last_word_connector'),)
  end
end
