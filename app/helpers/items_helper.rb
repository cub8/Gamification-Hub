# frozen_string_literal: true

module ItemsHelper
  def item_bought_line(count)
    return t('items.helpers.nobody_bought') if count.zero?

    t('items.helpers.bought', count: count)
  end

  def item_name(item)
    item.name.presence || t('items.helpers.name_placeholder')
  end

  def item_rules(item)
    item.didactic_description.presence || t('items.helpers.rules_placeholder')
  end

  def item_unlock_sentence(item)
    rank   = item.unlock_rank&.starting? ? nil : item.unlock_rank
    badges = item.unlock_badges.map(&:name).sort
    lives  = t(item.can_buy_at_0_lives ? 'items.sentences.lives_yes' : 'items.sentences.lives_no')

    return gh_fill(t('items.sentences.unlock_everyone'), lives: lives) if rank.nil? && badges.empty?

    gh_fill(t('items.sentences.unlock_restricted'),
            rank:   unlock_rank_clause(rank),
            badges: unlock_badges_clause(badges),
            lives:  lives,)
  end

  def item_discount_sentence(item, card, example)
    price = item.price.to_i
    return gh_fill(t('items.sentences.no_discount'), price: tag.b(price)) if card.max_discount.zero?
    return if example.none?

    paid = PriceCalculatorService.new(price: price, discount: Discount.new(example.percent)).calculate

    gh_fill(t('items.sentences.example'),
            holder:  example_holder_clause(example),
            percent: tag.b("#{example.percent}%"),
            paid:    tag.b(paid),
            price:   price,)
  end

  def item_discount_max_sentence(card)
    return if card.max_discount.zero?

    gh_fill(t('items.sentences.max'), holder: max_holder_clause(card), percent: tag.b("#{card.max_discount}%"))
  end

  def item_overlap_warnings(item, card = nil)
    warnings = []

    warnings << t('items.sentences.warn_cap', raw: card.raw_discount, cap: Discount::CAP_VALUE) if card&.capped?

    if discount_rank_covers_everyone?(item)
      warnings << if item.unlock_rank.starting?
                    t('items.sentences.warn_rank_everyone')
                  else
                    t('items.sentences.warn_rank_gate', rank: item.unlock_rank.name)
                  end
    end

    overlapping = (item.discount_badges & item.unlock_badges).sort_by { |badge| badge.name.to_s }
    overlapping.each do |badge|
      warnings << t('items.sentences.warn_badge_required', name: badge.name)
    end

    warnings
  end

  def item_unlock_rank_options(ranks, selected)
    options = ranks.map do |rank|
      data = { gh_name: rank.name, gh_gates: rank.starting? ? 'false' : 'true' }
      [t('items.helpers.unlock_option_rank', name: rank.name), rank.id, { data: data }]
    end

    blank = [t('items.helpers.unlock_option_everyone'), '', { data: { gh_name: '', gh_gates: 'false' } }]

    options_for_select([blank] + options, selected)
  end

  def item_discount_rank_options(ranks, selected)
    options = ranks.map do |rank|
      above = ranks.select { |other| other.required_currency_value.to_i >= rank.required_currency_value.to_i }
      best  = above.max_by { |other| other.discount.to_i }

      label = t('items.helpers.discount_option_rank', name: rank.name, discount: rank.discount.to_i)
      data  = {
        gh_discount: best&.discount.to_i,
        gh_name:     best&.name.to_s,
        gh_own:      rank.discount.to_i,
        gh_own_name: rank.name.to_s,
      }
      [label, rank.id, { data: data }]
    end

    blank_data = { data: { gh_discount: 0, gh_name: '', gh_own: 0, gh_own_name: '' } }
    blank      = [t('items.helpers.discount_option_none'), '', blank_data]

    options_for_select([blank] + options, selected)
  end

  # The templates and plural forms item_form_controller.ts needs to rebuild
  # the same sentences while the teacher types.
  def item_form_wording
    t('items.sentences').merge(
      t('items.labels').slice(:discount_up_to, :seal_rank, :seal_badge),
      t('items.helpers').slice(:name_placeholder, :rules_placeholder),
      buy: t('items.card.buy'),
    )
  end

  private

  def unlock_rank_clause(rank)
    return '' if rank.nil?

    gh_fill(t('items.sentences.unlock_rank'), rank: tag.b(rank.name))
  end

  def unlock_badges_clause(badges)
    return '' if badges.empty?

    gh_fill(plural_template('items.sentences.unlock_badges', badges.size), badges: tag.b(gh_and_list(badges)))
  end

  def example_holder_clause(example)
    names = example.badges.map(&:name)
    return holder_clause(example.rank&.name, nil) if names.empty?

    phrase = gh_fill(plural_template('items.sentences.holder_badges', names.size), badges: tag.b(gh_and_list(names)))
    holder_clause(example.rank&.name, phrase)
  end

  def max_holder_clause(card)
    badges = card.discount_badges

    phrase = case badges.size
             when 0 then nil
             when 1 then gh_fill(plural_template('items.sentences.holder_badges', 1), badges: tag.b(badges.first.name))
             else        t('items.sentences.holder_all_badges')
             end

    holder_clause(card.best_discount_rank&.name, phrase)
  end

  def holder_clause(rank_name, badge_phrase)
    rank = rank_name ? gh_fill(t('items.sentences.holder_rank'), rank: tag.b(rank_name)) : ''
    return rank if badge_phrase.nil?

    join = rank_name ? 'items.sentences.holder_join_and' : 'items.sentences.holder_join_with'
    safe_join([rank, gh_fill(t(join), phrase: badge_phrase)])
  end

  # The raw template of a pluralised key, with its other slots left in place
  # for gh_fill.
  def plural_template(key, count)
    slots = t(key).values.join.scan(/%\{(\w+)\}/).flatten.uniq - ['count']

    t(key, count: count, **slots.to_h { |slot| [slot.to_sym, "%{#{slot}}"] })
  end

  def discount_rank_covers_everyone?(item)
    floor   = item.min_rank_for_discount
    gate    = item.unlock_rank
    return false if floor.nil? || gate.nil?

    gate.required_currency_value.to_i >= floor.required_currency_value.to_i
  end
end
