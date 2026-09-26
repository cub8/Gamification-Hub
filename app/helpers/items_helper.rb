# frozen_string_literal: true

module ItemsHelper
  # The line in the foot of a teacher's item card (30-lists.js:36).
  def item_bought_line(count)
    return 'Jeszcze nikt nie kupił' if count.zero?

    "Kupiono #{count} #{gh_plural(count, 'raz', 'razy', 'razy')}"
  end

  def item_name(item)
    item.name.presence || 'Nazwa przedmiotu'
  end

  # "Co daje studentowi" as the card shows it. The placeholder is only ever
  # reached in the form preview, before the field has been typed into — the
  # model requires this text on a saved item.
  def item_rules(item)
    item.didactic_description.presence || 'Co daje studentowi…'
  end

  def item_unlock_sentence(item)
    rank   = item.unlock_rank&.starting? ? nil : item.unlock_rank
    badges = item.unlock_badges.map(&:name).sort

    parts = if rank.nil? && badges.empty?
              ['Każdy student może kupić ten przedmiot']
            else
              ['Kupią tylko studenci', *unlock_rank_clause(rank), *unlock_badges_clause(badges)]
            end

    safe_join(parts + [item_lives_clause(item)])
  end

  def item_discount_sentence(item, card, example)
    price = item.price.to_i
    return safe_join(['Bez zniżek. Każdy kupujący zapłaci ', tag.b(price), '.']) if card.max_discount.zero?
    # Nobody plausible to name — the maximum line below still says everything
    # there is to say about this item's discounts.
    return if example.none?

    paid = PriceCalculatorService.new(price: price, discount: Discount.new(example.percent)).calculate

    saving = tag.b("#{example.percent}%")
    tail   = [' zaoszczędzi ', saving, ' i zapłaci ', tag.b(paid), " zamiast #{price}."]

    safe_join(['Przykładowo: student', *example_holder_clause(example), *tail])
  end

  # The line beneath the example: what the best-off student in this group gets,
  # which is the number on the card's own "Zniżki do −X%" chip spelled out.
  def item_discount_max_sentence(card)
    return if card.max_discount.zero?

    saving = tag.b("#{card.max_discount}%")

    safe_join(['Maksymalnie: student', *max_holder_clause(card), ' uzyska zniżkę ', saving, '.'])
  end

  # Requirements that quietly cancel a discount out (30-item.js:33-36). Not
  # errors — the teacher may well mean it — so they render as notes, and the
  # form saves either way.
  def item_overlap_warnings(item, card = nil)
    warnings = []

    # Not an overlap but the same kind of note: discount a teacher has set up
    # and no student will ever receive.
    if card&.capped?
      warnings << "Zniżki sumują się do #{card.raw_discount}%, a sklep odejmie najwyżej " \
                  "#{Discount::CAP_VALUE}%. Nadwyżka przepada — rozważ niższe zniżki " \
                  'przy rangach i odznakach.'
    end

    if discount_rank_covers_everyone?(item)
      warnings << if item.unlock_rank.starting?
                    'Zniżka dla rang obejmie każdego kupującego.'
                  else
                    "Kupić mogą tylko studenci od rangi #{item.unlock_rank.name}, " \
                      'więc zniżka dla rang obejmie każdego kupującego.'
                  end
    end

    overlapping = (item.discount_badges & item.unlock_badges).sort_by { |badge| badge.name.to_s }
    overlapping.each do |badge|
      warnings << "Odznaka #{badge.name} jest wymagana do zakupu, " \
                  'więc jej zniżka obejmie każdego kupującego.'
    end

    warnings
  end

  def item_unlock_rank_options(ranks, selected)
    options = ranks.map do |rank|
      data = { gh_name: rank.name, gh_gates: rank.starting? ? 'false' : 'true' }
      ["od rangi #{rank.name}", rank.id, { data: data }]
    end

    blank = ['każdy student', '', { data: { gh_name: '', gh_gates: 'false' } }]

    options_for_select([blank] + options, selected)
  end

  def item_discount_rank_options(ranks, selected)
    options = ranks.map do |rank|
      above = ranks.select { |other| other.required_currency_value.to_i >= rank.required_currency_value.to_i }
      best  = above.max_by { |other| other.discount.to_i }

      label = "od #{rank.name} (−#{rank.discount.to_i}% i więcej)"
      # Two pairs, and they are not the same rung: `gh_discount`/`gh_name` are
      # the CEILING this floor implies — the best rung at or above it — which is
      # what the card's chip promises. `gh_own`/`gh_own_name` are the rung
      # itself, which is what an example student standing on it actually gets.
      data  = {
        gh_discount: best&.discount.to_i,
        gh_name:     best&.name.to_s,
        gh_own:      rank.discount.to_i,
        gh_own_name: rank.name.to_s,
      }
      [label, rank.id, { data: data }]
    end

    blank = ['brak', '', { data: { gh_discount: 0, gh_name: '', gh_own: 0, gh_own_name: '' } }]

    options_for_select([blank] + options, selected)
  end

  private

  def unlock_rank_clause(rank)
    return [] if rank.nil?

    [' z rangą ', tag.b(rank.name), ' lub wyższą']
  end

  def unlock_badges_clause(badges)
    return [] if badges.empty?

    noun = badges.size > 1 ? 'wszystkie odznaki' : 'odznakę'
    [", którzy mają #{noun} ", tag.b(gh_and_list(badges))]
  end

  def item_lives_clause(item)
    item.can_buy_at_0_lives ? '. Także przy 0 życiach.' : ', jeśli mają co najmniej 1 życie.'
  end

  # "z rangą X oraz odznakami A i B". `oraz` joins the two halves rather than
  # `i`, which gh_and_list already spends on the badge list itself.
  def example_holder_clause(example)
    names = example.badges.map(&:name)
    return holder_clause(example.rank&.name, nil) if names.empty?

    noun = names.size > 1 ? 'odznakami ' : 'odznaką '

    holder_clause(example.rank&.name, [noun, tag.b(gh_and_list(names))])
  end

  # The ceiling's holder. "wszystkimi odznakami" rather than a list: every badge
  # in the group counts toward a discount (DiscountCalculatorService), and
  # naming them all is exactly what the example above exists to avoid. With one
  # badge in the group there is nothing to summarise, so it is named.
  def max_holder_clause(card)
    badges = card.discount_badges

    phrase = case badges.size
             when 0 then nil
             when 1 then ['odznaką ', tag.b(badges.first.name)]
             else        ['wszystkimi odznakami']
             end

    holder_clause(card.best_discount_rank&.name, phrase)
  end

  # Joins the two halves. `badge_phrase` arrives whole, because Polish puts
  # "wszystkimi" BEFORE the noun and a name after it — one order does not serve
  # both.
  def holder_clause(rank_name, badge_phrase)
    clause = []
    clause += [' z rangą ', tag.b(rank_name)] if rank_name
    return clause if badge_phrase.nil?

    clause + [rank_name ? ' oraz ' : ' z ', *badge_phrase]
  end

  # The discount's floor is at or below the purchase requirement, so nobody who
  # can buy the item is below it.
  def discount_rank_covers_everyone?(item)
    floor   = item.min_rank_for_discount
    gate    = item.unlock_rank
    return false if floor.nil? || gate.nil?

    gate.required_currency_value.to_i >= floor.required_currency_value.to_i
  end
end
