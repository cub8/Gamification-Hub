# frozen_string_literal: true

class CurrencyAdjustmentForm
  include ActiveModel::Model

  PERMITTED = %i[sign amount].freeze
  DEFAULT_SIGN = 1

  attr_reader :student, :sign, :amount

  class << self
    def for(student) = new(student: student, sign: DEFAULT_SIGN, amount: nil)

    def from_params(student, params)
      attributes = params.fetch(:currency_adjustment, {}).permit(*PERMITTED)

      new(student: student,
          sign:    attributes[:sign].to_s == '-1' ? -1 : 1,
          amount:  attributes[:amount],)
    end
  end

  def initialize(student:, sign: DEFAULT_SIGN, amount: nil)
    @student = student
    @sign    = sign.to_i.negative? ? -1 : 1
    @amount  = amount
  end

  def story_group = student.story_group

  def positive? = sign.positive?

  def value
    return @value if defined?(@value)

    text   = amount.to_s.strip
    @value = text.match?(/\A\d+\z/) ? text.to_i : nil
  end

  def signed_value = value.nil? ? 0 : value * sign

  def balance = student.current_currency.to_i
  def total   = student.total_currency.to_i

  def new_balance = balance + signed_value
  def new_total   = total + [signed_value, 0].max
  def total_changed? = new_total != total

  def current_rank = @current_rank ||= rank_at(total)
  def new_rank     = @new_rank ||= rank_at(new_total)
  def rank_changed? = current_rank&.id != new_rank&.id

  def valid_amount?
    validate
    errors.empty?
  end

  def validate
    errors.clear

    if value.nil?
      errors.add(:amount, 'Podaj kwotę.')
    elsif value.zero?
      errors.add(:amount, 'Podaj kwotę większą od zera.')
    elsif new_balance.negative?
      errors.add(:amount, "Student ma tylko #{balance} do wydania.")
    end

    errors.empty?
  end

  def error_for(attribute) = errors[attribute].first

  def save(granted_by_user:)
    return false unless validate

    CurrencyAdjusterService.new(student: student, granted_by_user: granted_by_user)
                           .adjust(signed_value)
    true
  end

  private

  def rank_at(collected)
    ladder.reverse_each.find { |rank| rank.required_currency_value.to_i <= collected }
  end

  def ladder
    @ladder ||= story_group.ranks.by_threshold.to_a
  end
end
