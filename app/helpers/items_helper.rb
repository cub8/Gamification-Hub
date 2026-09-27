# frozen_string_literal: true

module ItemsHelper
  def item_bought_line(count)
    return 'Jeszcze nikt nie kupił' if count.zero?

    "Kupiono #{count} #{gh_plural(count, 'raz', 'razy', 'razy')}"
  end

  def item_name(item)
    item.name.presence || 'Nazwa przedmiotu'
  end

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
    return if example.none?

    paid = PriceCalculatorService.new(price: price, discount: Discount.new(example.percent)).calculate

    saving = tag.b("#{example.percent}%")
    tail   = [' zaoszczędzi ', saving, ' i zapłaci ', tag.b(paid), " zamiast #{price}."]

    safe_join(['Przykładowo: student', *example_holder_clause(example), *tail])
  end

  def item_discount_max_sentence(card)
    return if card.max_discount.zero?

    saving = tag.b("#{card.max_discount}%")

    safe_join(['Maksymalnie: student', *max_holder_clause(card), ' uzyska zniżkę ', saving, '.'])
  end

  def item_overlap_warnings(item, card = nil)
    warnings = []

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

  def example_holder_clause(example)
    names = example.badges.map(&:name)
    return holder_clause(example.rank&.name, nil) if names.empty?

    noun = names.size > 1 ? 'odznakami ' : 'odznaką '

    holder_clause(example.rank&.name, [noun, tag.b(gh_and_list(names))])
  end

  def max_holder_clause(card)
    badges = card.discount_badges

    phrase = case badges.size
             when 0 then nil
             when 1 then ['odznaką ', tag.b(badges.first.name)]
             else        ['wszystkimi odznakami']
             end

    holder_clause(card.best_discount_rank&.name, phrase)
  end

  def holder_clause(rank_name, badge_phrase)
    clause = []
    clause += [' z rangą ', tag.b(rank_name)] if rank_name
    return clause if badge_phrase.nil?

    clause + [rank_name ? ' oraz ' : ' z ', *badge_phrase]
  end

  def discount_rank_covers_everyone?(item)
    floor   = item.min_rank_for_discount
    gate    = item.unlock_rank
    return false if floor.nil? || gate.nil?

    gate.required_currency_value.to_i >= floor.required_currency_value.to_i
  end
end
