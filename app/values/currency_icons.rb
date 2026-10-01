# frozen_string_literal: true

class CurrencyIcons < PresetSet
  KEYS = %w[carrot coin gem pearl bit].freeze

  LABELS = {
    'bit'    => 'Bit',
    'carrot' => 'Marchewka',
    'coin'   => 'Moneta',
    'gem'    => 'Klejnot',
    'pearl'  => 'Perła',
  }.freeze

  class << self
    def dir = 'currency'
    def labels = LABELS
  end
end
