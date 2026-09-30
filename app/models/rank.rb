# frozen_string_literal: true

class Rank < ApplicationRecord
  include Iconable

  belongs_to :story_group

  has_icon_art :icon, glyphs: Glyphs::RANK

  validates :name, presence: { message: 'Podaj nazwę rangi.' },
                   length:   { maximum: 40 }

  validates :discount, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to:    100,
    message:                  'Zniżka musi mieścić się między 0 a 100%.',
  }

  validates :required_currency_value, numericality: {
    only_integer:             true,
    greater_than_or_equal_to: 0,
    message:                  'Próg nie może być ujemny.',
  }

  validate :threshold_free_in_group

  scope :by_threshold, -> { order(:required_currency_value, :id) }

  def threshold_free_in_group
    return if story_group.nil? || required_currency_value.nil?

    clash = story_group.ranks.where(required_currency_value: required_currency_value)
                       .where.not(id: id)
                       .first
    return if clash.nil?

    errors.add(:required_currency_value,
               "Ranga #{clash.name} ma już próg #{clash.required_currency_value}. Wybierz inny.",)
  end

  def starting?
    required_currency_value&.zero? || false
  end

  def dependent_items
    Item.where(unlock_rank: self).or(Item.where(min_rank_for_discount: self))
  end
end
