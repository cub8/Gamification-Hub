# frozen_string_literal: true

class GroupArt < PresetSet
  # Picker order, from the wizard (30-form.js:21-27).
  KEYS = %w[castle waves tables flow brackets].freeze

  # The wizard's own labels (its `l` keys) — the settings screen names its
  # tiles with the raw key instead ("Grafika castle", 30-isg.js:53), which
  # tells a screen reader nothing.
  LABELS = {
    'brackets' => 'Kod',
    'castle'   => 'Zamek',
    'flow'     => 'Algorytm',
    'tables'   => 'Tabele',
    'waves'    => 'Morze',
  }.freeze

  class << self
    def dir = 'art'
    def labels = LABELS
  end
end
