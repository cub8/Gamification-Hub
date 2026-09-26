# frozen_string_literal: true

class StoryGroup < ApplicationRecord
  # How much of the ranking a student sees once `ranking_enabled` is on
  # (DECISIONS.md:36). Prefixed, because `full?` on a StoryGroup would read as
  # a question about the group, not about its ranking.
  enum :ranking_mode, { podium_and_own: 0, full: 1 }, prefix: :ranking

  RANKING_MODE_LABELS = {
    'podium_and_own' => 'Podium i własne miejsce',
    'full'           => 'Pełny ranking',
  }.freeze

  ACCEPTABLE_ICON_TYPES = ['image/gif', 'image/jpeg', 'image/png'].freeze

  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id'
  has_many :items, dependent: :destroy
  has_many :ranks, dependent: :destroy
  has_many :badges, dependent: :destroy
  has_many :student_memberships, class_name: 'StoryGroupStudent', foreign_key: 'story_group_id', dependent: :destroy
  has_many :teacher_memberships, class_name: 'StoryGroupTeacher', foreign_key: 'story_group_id', dependent: :destroy
  has_many :students, through: :student_memberships, source: :user
  has_many :teachers, through: :teacher_memberships, source: :user
  has_one_attached :icon
  has_one_attached :currency_icon
  has_many :activity_group_templates, dependent: :destroy
  has_many :activity_groups, dependent: :destroy
  has_many :invites, class_name: 'StoryGroupInvite', foreign_key: 'story_group_id', dependent: :destroy

  # Required, as the mockup has them (30-isg.js:95) and as Rank, Badge and Item
  # already do. Both are load-bearing: the name is how the group is addressed
  # everywhere, and the currency name is read aloud after every amount, so a
  # blank one renders "12 " on every card in the shop.
  validates :name, presence: { message: 'Podaj nazwę grupy.' },
                   length:   { maximum: 40 }
  validates :currency_name, presence: { message: 'Podaj nazwę waluty.' },
                            length:   { maximum: 40 }
  validates :description, length: { maximum: 1024 }
  validate :acceptable_icon
  validate :acceptable_currency_icon
  validates :default_lives, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # The pickers' own sets, not every file on disk. Rendering is looser on
  # purpose (ApplicationHelper accepts anything in the directory), so a group whose
  # preset is later retired still shows it.
  validates :icon_glyph, inclusion: { in: GroupArt::KEYS, message: 'Nieznana grafika.' },
                         allow_nil: true
  validates :currency_icon_glyph,
            inclusion: { in: CurrencyIcons::KEYS, message: 'Nieznana ikona.' },
            allow_nil: true

  # "Wyłączony" / "Podium i własne miejsce" / "Pełny ranking" — one sentence for
  # the overview's KPI tile and, later, for the group-settings summary.
  def ranking_summary
    return 'Wyłączony' unless ranking_enabled?

    RANKING_MODE_LABELS.fetch(ranking_mode, ranking_mode)
  end

  # `:upload` or a preset key, per image. One accessor each so no view has to
  # re-derive the rule — mirrors Rank#art.
  def art
    icon_glyph.presence || (icon.attached? ? :upload : nil)
  end

  def currency_art
    currency_icon_glyph.presence || (currency_icon.attached? ? :upload : nil)
  end

  private

  def acceptable_icon
    acceptable_image(:icon)
  end

  def acceptable_currency_icon
    acceptable_image(:currency_icon)
  end

  # The settings form renders these straight into its `.gh-field-error` slot, so the
  # message is Polish like every other piece of copy in the app.
  def acceptable_image(attribute)
    attachment = public_send(attribute)
    return unless attachment.attached?
    return if ACCEPTABLE_ICON_TYPES.include?(attachment.content_type)

    errors.add(attribute, 'Wgraj plik JPG, PNG albo GIF.')
  end
end
