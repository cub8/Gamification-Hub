# frozen_string_literal: true

class StoryGroupStudent < ApplicationRecord
  belongs_to :user
  belongs_to :story_group

  has_many :students_activity_group_categories, foreign_key: :student_id, dependent: :destroy
  has_many :students_badges, dependent: :destroy
  has_many :currency_transactions,              foreign_key: :student_id, dependent: :destroy
  has_many :students_items, dependent: :destroy
  has_many :badges, through: :students_badges

  delegate :full_name, :university_number, :email, to: :user
  scope :with_user, -> { includes(:user) }

  before_validation :set_default_lives_from_group, on: :create

  normalizes :nickname, with: ->(nickname) { nickname&.strip.presence }

  validates :user_id, uniqueness: { scope: :story_group_id }
  validates :lives, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Optional on purpose: leaving it blank means "show my real name", which the
  # join screen offers explicitly. The mockup makes a nickname mandatory; we do
  # not. Unique per group and case-insensitively so two people cannot be told
  # apart only by capitals — backed by a partial functional index.
  validates :nickname,
            length:      { in: 2..24, message: 'Pseudonim musi mieć od 2 do 24 znaków.' },
            allow_blank: true
  # The mockup's own sentence (30-gh.js:60). Written out rather than left as
  # Rails' default because it surfaces in two places — the join dialog and
  # "Ustawienia w grupie" — and both are Polish.
  validates :nickname,
            uniqueness:  {
              scope:          :story_group_id,
              case_sensitive: false,
              message:        'Ten pseudonim jest już zajęty w tej grupie.',
            },
            allow_blank: true

  def set_default_lives_from_group
    self.lives ||= story_group.default_lives
  end

  def display_name
    nickname.presence || full_name
  end

  def update_lives(change)
    new_lives = lives + change

    update(lives: new_lives)
  end

  def rank
    unless @rank_at == total_currency
      @rank_at = total_currency
      @rank    = story_group.ranks
                            .where('required_currency_value <= ?', total_currency)
                            .order(required_currency_value: :desc)
                            .first
    end

    @rank
  end

  # The rank being worked toward. Nil once the top rank is reached, and also
  # nil when the group defines no ranks at all — callers must handle both.
  def next_rank
    unless @next_rank_at == total_currency
      @next_rank_at = total_currency
      @next_rank    = story_group.ranks.where('required_currency_value > ?', total_currency)
                                 .order(required_currency_value: :asc)
                                 .first
    end

    @next_rank
  end
end
