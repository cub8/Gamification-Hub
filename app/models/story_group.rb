# frozen_string_literal: true

class StoryGroup < ApplicationRecord
  include Iconable

  enum :ranking_mode, { podium_and_own: 0, full: 1 }, prefix: :ranking

  class << self
    def ranking_mode_label(mode) = I18n.t("story_groups.ranking_modes.#{mode}")
  end

  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id'
  has_many :items, dependent: :destroy
  has_many :ranks, dependent: :destroy
  has_many :badges, dependent: :destroy
  has_many :student_memberships, class_name: 'StoryGroupStudent', foreign_key: 'story_group_id', dependent: :destroy
  has_many :teacher_memberships, class_name: 'StoryGroupTeacher', foreign_key: 'story_group_id', dependent: :destroy
  has_many :students, through: :student_memberships, source: :user
  has_many :teachers, through: :teacher_memberships, source: :user
  has_many :activity_group_templates, dependent: :destroy
  has_many :activity_groups, dependent: :destroy
  has_many :invites, class_name: 'StoryGroupInvite', foreign_key: 'story_group_id', dependent: :destroy

  has_icon_art :icon, glyphs: GroupArt::KEYS, required: false
  has_icon_art :currency_icon, glyphs: CurrencyIcons::KEYS, glyph_message: :unknown_icon, required: false

  validates :name, presence: true, length: { maximum: 40 }
  validates :currency_name, presence: true, length: { maximum: 40 }
  validates :description, length: { maximum: 1024 }
  validates :default_lives, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def ranking_summary
    return I18n.t('story_groups.ranking_off') unless ranking_enabled?

    self.class.ranking_mode_label(ranking_mode)
  end
end
