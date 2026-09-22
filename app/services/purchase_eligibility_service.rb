# frozen_string_literal: true

class PurchaseEligibilityService
  # Why a purchase is blocked, as a record rather than a sentence.
  #
  # `errors` was always the whole answer, and a screen that wants to name the
  # rank a student is short of — or draw a bar toward it — cannot parse it back
  # out of Polish. The shop card reads these; the till still reads `errors`.
  #
  # kind: :lives (record nil), :rank (the Rank), :badge (the Badge).
  Reason = Data.define(:kind, :record)

  class Result
    attr_reader :errors, :reasons

    def initialize(errors, reasons = [])
      @errors  = errors
      @reasons = reasons
    end

    def eligible?
      @errors.empty?
    end
  end

  def initialize(student:, item:)
    @student = student
    @item = item
    @errors = []
    @reasons = []
  end

  def call
    check_lives!
    check_rank!
    check_badges!

    Result.new(@errors, @reasons)
  end

  private

  def check_lives!
    return unless @student.lives == 0 && !@item.can_buy_at_0_lives

    @errors << 'Wymagane jest posiadanie przynajmniej jednego życia.'
    @reasons << Reason.new(:lives, nil)
  end

  def check_rank!
    return unless @item.unlock_rank.present?

    return unless @student.rank.nil? || @student.total_currency < @item.unlock_rank.required_currency_value

    @errors << "Wymagana ranga: #{@item.unlock_rank.name}."
    @reasons << Reason.new(:rank, @item.unlock_rank)
  end

  def check_badges!
    return if @item.unlock_badges.none?

    missing_badges = @item.unlock_badges - @student.badges

    return if missing_badges.none?

    badge_names = missing_badges.map(&:name).join(', ')
    @errors << "Brakujące odznaki: #{badge_names}."
    # One reason per badge, unlike the single error above: a card lists them as
    # separate lines and the seal names only the first.
    missing_badges.sort_by { |badge| badge.name.to_s }
                  .each { |badge| @reasons << Reason.new(:badge, badge) }
  end
end
