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

  validates :name, :currency_name, length: { maximum: 40 }
  validates :description, length: { maximum: 1024 }
  validate :acceptable_icon
  validate :acceptable_currency_icon
  validates :default_lives, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # "Wyłączony" / "Podium i własne miejsce" / "Pełny ranking" — one sentence for
  # the overview's KPI tile and, later, for the group-settings summary.
  def ranking_summary
    return 'Wyłączony' unless ranking_enabled?

    RANKING_MODE_LABELS.fetch(ranking_mode, ranking_mode)
  end

  def acceptable_icon
    return unless icon.attached?

    acceptable_types = ['image/gif', 'image/jpeg', 'image/png']
    return if acceptable_types.include?(icon.content_type)

    errors.add(:icon, 'must be a GIF, JPG or PNG image')
  end

  def acceptable_currency_icon
    return unless currency_icon.attached?

    acceptable_types = ['image/gif', 'image/jpeg', 'image/png']
    return if acceptable_types.include?(currency_icon.content_type)

    errors.add(:currency_icon, 'must be a GIF, JPG or PNG image')
  end
end
