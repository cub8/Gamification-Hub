# frozen_string_literal: true

class PurchaseEligibilityService
  class Result
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def eligible?
      @errors.empty?
    end
  end

  def initialize(student:, item:)
    @student = student
    @item = item
    @errors = []
  end

  def call
    check_lives!
    check_rank!
    check_badges!

    Result.new(@errors)
  end

  private

  def check_lives!
    return unless @student.lives == 0 && !@item.can_buy_at_0_lives

    @errors << 'Wymagane jest posiadanie przynajmniej jednego życia.'

  end

  def check_rank!
    return unless @item.unlock_rank.present?

    return unless @student.rank.nil? || @student.total_currency < @item.unlock_rank.required_currency_value

    @errors << "Wymagana ranga: #{@item.unlock_rank.name}."

  end

  def check_badges!
    return if @item.unlock_badges.none?

    missing_badges = @item.unlock_badges - @student.badges

    return if missing_badges.none?

    badge_names = missing_badges.map(&:name).join(', ')
    @errors << "Brakujące odznaki: #{badge_names}."

  end
end
