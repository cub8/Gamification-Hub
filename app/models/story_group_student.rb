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

  validates :user_id, uniqueness: { scope: :story_group_id }
  validates :lives, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Optional on purpose: leaving it blank means "show my real name", which the
  # join screen offers explicitly. The mockup makes a nickname mandatory; we do
  # not. Unique per group and case-insensitively so two people cannot be told
  # apart only by capitals — backed by a partial functional index.
  validates :nickname, length: { in: 2..24 }, allow_blank: true
  validates :nickname,
            uniqueness:  { scope: :story_group_id, case_sensitive: false },
            allow_blank: true

  def set_default_lives_from_group
    self.lives ||= story_group.default_lives
  end

  # What everyone else in the group sees: the ranking, the teacher's lists, the
  # confirmation after joining. Never blank.
  def display_name
    nickname.presence || full_name
  end

  def update_lives(change)
    new_lives = lives + change

    update(lives: new_lives)
  end

  # Memoised against total_currency, because that value is the whole of the
  # answer. The shop asks once per item it renders, and a fresh query per card
  # is a query per card. Keyed on the total rather than computed once, so a
  # student whose total changes inside the same request still gets the right
  # rung — and `reload` is not needed to clear it.
  def rank
    unless @rank_at == total_currency
      @rank_at = total_currency
      @rank    = story_group.ranks.where('required_currency_value <= ?', total_currency)
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
