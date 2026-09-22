# frozen_string_literal: true

class Badge < ApplicationRecord
  # The art is one of two things, never both: an uploaded image, or a preset
  # glyph named by `icon_glyph` (a key into Glyphs, whose files live
  # in app/assets/images — nothing is ever copied into the database). Keeping
  # the attachment when a preset is chosen is deliberate: it lets a teacher
  # switch back without re-uploading. Same contract as Rank.
  has_one_attached :icon

  has_many :students_badges, dependent: :destroy

  belongs_to :story_group

  ACCEPTABLE_ICON_TYPES = ['image/gif', 'image/jpeg', 'image/png'].freeze

  validates :name, presence: { message: 'Podaj nazwę odznaki.' },
                   length:   { maximum: 50 }

  # "Jak zdobyć" — required, because it is the only thing on the back of a badge
  # a student has not earned yet (30-br.js:47). A badge whose rule is blank shows
  # that student an empty card and tells them nothing.
  validates :didactic_description, presence: { message: 'Napisz, jak zdobyć tę odznakę.' },
                                   length:   { maximum: 255 }

  validates :story_description, length: { maximum: 255 }

  validates :discount, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to:    100,
    message:                  'Zniżka musi mieścić się między 0 a 100%.',
  }

  # The picker's own set, not every glyph on disk: a badge should carry badge
  # art. Rendering is looser on purpose (ApplicationHelper#gh_glyph accepts anything
  # in the directory), so a record whose key is later retired still shows it.
  validates :icon_glyph, inclusion: { in: Glyphs::BADGE, message: 'Nieznana grafika.' },
                         allow_nil: true

  validate :acceptable_icon
  validate :art_chosen

  # Soft delete (DECISIONS.md:28). NOT a default_scope: StudentsBadge#badge and
  # the discount and eligibility services have to go on resolving a deleted
  # badge, because a student who earned one keeps it — and keeps its discount.
  # Lists and pickers ask for `kept` themselves.
  scope :kept,    -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # Badges have no natural order of their own — no threshold, no rank — so the
  # lists read alphabetically, with the id breaking ties so the order is stable.
  scope :by_name, -> { order(:name, :id) }

  def acceptable_icon
    return unless icon.attached?
    return if ACCEPTABLE_ICON_TYPES.include?(icon.content_type)

    errors.add(:icon, 'Grafika musi być plikiem GIF, JPG lub PNG.')
  end

  # Every entity card shows art, so "no art" is not a state the design has — a
  # record without it falls through to a generic fallback icon that says
  # nothing. The picker always has a tile selected, so in practice this only
  # fires on a record that predates the rule or on a hand-built request.
  def art_chosen
    return if icon_glyph.present? || icon.attached?

    errors.add(:icon_glyph, 'Wybierz gotową grafikę albo wgraj własną.')
  end

  def deleted? = deleted_at.present?

  # Validations are skipped on purpose: a badge written before the rule became
  # required would otherwise be undeletable until someone filled that field in,
  # which is the opposite of what the teacher asked for.
  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  # `:upload` or a glyph key. One accessor so no view has to re-derive the rule.
  def art
    icon_glyph.presence || (icon.attached? ? :upload : nil)
  end

  def upload?
    art == :upload
  end

  # Items that point at this badge, through either of Item's two badge
  # associations. Unlike Rank#dependent_items these are not delete blockers — a
  # soft delete breaks no foreign key — but the confirm dialog names the ones
  # that UNLOCK on this badge, because those become unbuyable for anyone who
  # does not already hold it.
  def dependent_items
    Item.where(id: ItemsUnlockBadge.where(badge_id: id).select(:item_id))
        .or(Item.where(id: ItemsMinBadgesForDiscount.where(badge_id: id).select(:item_id)))
  end

  # Just the unlock side of the above — what the delete dialog warns about.
  def unlocking_items
    Item.where(id: ItemsUnlockBadge.where(badge_id: id).select(:item_id))
  end
end
