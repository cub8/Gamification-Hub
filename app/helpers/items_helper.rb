# frozen_string_literal: true

# Copy for the item screens. Screen-specific labels live in the screen's own
# helper, not in RedesignHelper.
#
# The three consequence sentences here (unlock / discount / warnings) are
# rendered on the server so the form is correct before a keystroke and with
# JavaScript off. item_form_controller rewrites them as you type; keep the two
# in step.
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

  # "Kupią tylko studenci z rangą X lub wyższą, którzy mają odznakę Y, jeśli
  # mają co najmniej 1 życie." (30-item.js:27-29).
  #
  # A rank at threshold 0 is skipped, the same way Redesign::ItemCard skips it:
  # everyone holds it, so naming it would describe a gate that stops nobody and
  # the sentence would contradict the card beside it.
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

  # What the discounts add up to, as one worked example (30-item.js:30-32).
  #
  # An EXAMPLE, deliberately, not a superlative: a student qualifies by meeting
  # ANY one of the conditions (DECISIONS.md:33, DiscountCalculatorService), so
  # "najwięcej zaoszczędzi…" would read as though all of them were needed. This
  # describes one student who happens to meet them all, which is where the
  # card's "Zniżki do −X%" ceiling comes from.
  def item_discount_sentence(item, card)
    price = item.price.to_i
    return safe_join(['Bez zniżek. Każdy kupujący zapłaci ', tag.b(price), '.']) if card.max_discount.zero?

    paid = PriceCalculatorService.new(price: price, discount: Discount.new(card.max_discount)).calculate

    saving = tag.b("#{card.max_discount}%")
    tail   = [' zaoszczędzi ', saving, ' i zapłaci ', tag.b(paid), " zamiast #{price}."]

    safe_join(['Przykładowo: student', *discount_holder_clause(card), *tail])
  end

  # Requirements that quietly cancel a discount out (30-item.js:33-36). Not
  # errors — the teacher may well mean it — so they render as notes, and the
  # form saves either way.
  def item_overlap_warnings(item)
    warnings = []

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

  # The "Kupić może" select (30-item.js:50). Each option carries the bare rank
  # name in a data attribute: the option's own text is a phrase ("od rangi X"),
  # and item_form_controller needs the name alone for the seal and the
  # requirement line.
  # `gh_gates` says whether choosing this rung locks anybody out: a rank at
  # threshold 0 is held by every student, so it gates nobody.
  # item_form_controller reads it to decide whether the card can ever be sealed.
  def item_unlock_rank_options(ranks, selected)
    options = ranks.map do |rank|
      data = { gh_name: rank.name, gh_gates: rank.starting? ? 'false' : 'true' }
      ["od rangi #{rank.name}", rank.id, { data: data }]
    end

    blank = ['każdy student', '', { data: { gh_name: '', gh_gates: 'false' } }]

    options_for_select([blank] + options, selected)
  end

  # The "Zniżka dla rang" select (30-item.js:54).
  #
  # The label is the rung's own discount, as the mockup writes it; the data is
  # the CEILING that choosing this rung implies — the best discount anywhere at
  # or above it — because that is what the card's "Zniżki do −X%" promises and
  # the two must agree.
  def item_discount_rank_options(ranks, selected)
    options = ranks.map do |rank|
      above = ranks.select { |other| other.required_currency_value.to_i >= rank.required_currency_value.to_i }
      best  = above.max_by { |other| other.discount.to_i }

      label = "od #{rank.name} (−#{rank.discount.to_i}% i więcej)"
      [label, rank.id, { data: { gh_discount: best&.discount.to_i, gh_name: best&.name.to_s } }]
    end

    options_for_select([['brak', '', { data: { gh_discount: 0, gh_name: '' } }]] + options, selected)
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
  def discount_holder_clause(card)
    rank   = card.best_discount_rank
    badges = card.item.discount_badges.map(&:name).sort

    clause = []
    clause += [' z rangą ', tag.b(rank.name)] if rank
    if badges.any?
      noun = badges.size > 1 ? 'odznakami' : 'odznaką'
      clause += [rank ? ' oraz ' : ' z ', "#{noun} ", tag.b(gh_and_list(badges))]
    end
    clause
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
