# frozen_string_literal: true

class Rank < ApplicationRecord
  # The art is one of two things, never both: an uploaded image, or a preset
  # glyph named by `icon_glyph` (a key into Redesign::Glyphs, whose files live
  # in app/assets/images — nothing is ever copied into the database). Keeping
  # the attachment when a preset is chosen is deliberate: it lets a teacher
  # switch back without re-uploading.
  has_one_attached :icon

  belongs_to :story_group

  ACCEPTABLE_ICON_TYPES = ['image/gif', 'image/jpeg', 'image/png'].freeze

  validates :name, presence: { message: 'Podaj nazwę rangi.' },
                   length:   { maximum: 40 }

  validates :discount, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to:    100,
    message:                  'Zniżka musi mieścić się między 0 a 100%.',
  }

  validates :required_currency_value,
            numericality: {
              only_integer:             true,
              greater_than_or_equal_to: 0,
              message:                  'Próg nie może być ujemny.',
            }

  # The picker's own set, not every glyph on disk: a rank should carry rank art.
  # Rendering is looser on purpose (RedesignHelper#gh_glyph accepts anything in
  # the directory), so a record whose key is later retired still shows it.
  validates :icon_glyph, inclusion: { in: Redesign::Glyphs::RANK, message: 'Nieznana grafika.' },
                         allow_nil: true

  validate :acceptable_icon
  validate :threshold_free_in_group

  # Ascending, which is the order every ladder is computed in. The screens
  # reverse it for display — the mockup shows the highest rung first
  # (30-lists.js:26, 30-sp.js:22).
  scope :by_threshold, -> { order(:required_currency_value, :id) }

  def acceptable_icon
    return unless icon.attached?
    return if ACCEPTABLE_ICON_TYPES.include?(icon.content_type)

    errors.add(:icon, 'Grafika musi być plikiem GIF, JPG lub PNG.')
  end

  # Two rungs at the same threshold make "which rank do I hold" arbitrary, so
  # the threshold is what identifies a rung. Written by hand rather than as
  # `uniqueness:` because the message has to name the rank already sitting
  # there, the way the mockup's does (30-br.js:86).
  def threshold_free_in_group
    return if story_group.nil? || required_currency_value.nil?

    clash = story_group.ranks.where(required_currency_value: required_currency_value)
                       .where.not(id: id)
                       .first
    return if clash.nil?

    errors.add(:required_currency_value,
               "Ranga #{clash.name} ma już próg #{clash.required_currency_value}. Wybierz inny.",)
  end

  # `:upload` or a glyph key. One accessor so no view has to re-derive the rule.
  def art
    icon_glyph.presence || (icon.attached? ? :upload : nil)
  end

  def upload?
    art == :upload
  end

  # The lowest rung is only "Ranga startowa" if it actually starts at nothing.
  # The mockup keys that label off array index 0 (30-lists.js:28), which
  # mislabels a ladder whose first rung is at 30 — and a group need not define a
  # rank at 0 at all, in which case a student below the first threshold simply
  # has no rank.
  def starting?
    required_currency_value&.zero? || false
  end

  # Items that point at this rank, through either of Item's two rank
  # associations. Both are real foreign keys (schema.rb:275-276), so destroying
  # a referenced rank raises rather than cascading — RanksController refuses and
  # names these instead.
  def dependent_items
    Item.where(unlock_rank: self).or(Item.where(min_rank_for_discount: self))
  end
end
