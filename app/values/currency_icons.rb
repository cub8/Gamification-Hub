# frozen_string_literal: true

class CurrencyIcons < PresetSet
  KEYS = %w[carrot coin gem pearl bit].freeze

  class << self
    def dir = 'currency'
  end
end
