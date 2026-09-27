# frozen_string_literal: true

class Rank < ApplicationRecord
  ACCEPTABLE_ICON_TYPES = ['image/gif', 'image/jpeg', 'image/png'].freeze

  has_one_attached :icon

  belongs_to :story_group

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

  validates :icon_glyph, inclusion: { in: Glyphs::RANK, message: 'Nieznana grafika.' }, allow_nil: true

  validate :acceptable_icon
  validate :art_chosen
  validate :threshold_free_in_group

  scope :by_threshold, -> { order(:required_currency_value, :id) }

  def acceptable_icon
    return unless icon.attached?
    return if ACCEPTABLE_ICON_TYPES.include?(icon.content_type)

    errors.add(:icon, 'Grafika musi być plikiem GIF, JPG lub PNG.')
  end

  def art_chosen
    return if icon_glyph.present? || icon.attached?

    errors.add(:icon_glyph, 'Wybierz gotową grafikę albo wgraj własną.')
  end

  def threshold_free_in_group
    return if story_group.nil? || required_currency_value.nil?

    clash = story_group.ranks.where(required_currency_value: required_currency_value)
                       .where.not(id: id)
                       .first
    return if clash.nil?

    errors.add(:required_currency_value,
               "Ranga #{clash.name} ma już próg #{clash.required_currency_value}. Wybierz inny.",)
  end

  def art
    icon_glyph.presence || (icon.attached? ? :upload : nil)
  end

  def upload?
    art == :upload
  end

  def starting?
    required_currency_value&.zero? || false
  end

  def dependent_items
    Item.where(unlock_rank: self).or(Item.where(min_rank_for_discount: self))
  end
end
