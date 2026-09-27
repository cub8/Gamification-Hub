# frozen_string_literal: true

class GroupArt < PresetSet
  KEYS = %w[castle waves tables flow brackets].freeze

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
