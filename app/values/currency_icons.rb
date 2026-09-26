# frozen_string_literal: true

class CurrencyIcons < PresetSet
  # Picker order: the wizard's four (30-form.js:15-18), then `bit`.
  KEYS = %w[carrot coin gem pearl bit].freeze

  # The wizard's CVN map, plus a name for `bit` — the mockup's CUR table
  # declines it as "Bit / Bity / Bitów" (00-shared.js:97).
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
