# frozen_string_literal: true

module ShopHelper
  # "Masz 120 do wydania."
  #
  # The number comes before "do wydania" so the currency's name never has to be
  # declined: a group holds one nominative form ("marchewki") and Polish wants
  # the genitive here. ranks/_teacher_ladder.html.haml:8 makes the same dodge.
  def shop_balance_sentence(balance)
    safe_join(['Masz ', tag.b(balance), ' do wydania.'])
  end

  # "Twoje odznaki Mechanik i Nawigator obniżają ceny niektórych przedmiotów."
  # Nil when the student holds none that discount anything, which is the state
  # every student starts in.
  def shop_discount_sentence(badges)
    return if badges.empty?

    names = badges.map { |badge| tag.b(badge.name) }
    lead  = gh_plural(badges.size, 'Twoja odznaka ', 'Twoje odznaki ', 'Twoje odznaki ')
    verb  = gh_plural(badges.size, ' obniża ', ' obniżają ', ' obniżają ')

    safe_join([lead, gh_and_list_html(names), verb, 'ceny niektórych przedmiotów.'])
  end

  # gh_and_list, but for parts that are already markup: Array#join would hand
  # safe_join a plain String and every <b> would come back escaped.
  def gh_and_list_html(parts)
    return parts.first if parts.size < 2

    safe_join([safe_join(parts[0..-2], ', '), parts.last], ' i ')
  end
end
