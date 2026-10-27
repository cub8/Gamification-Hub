# frozen_string_literal: true

class GroupArt < PresetSet
  KEYS = %w[castle waves tables flow brackets].freeze

  class << self
    def dir = 'art'
  end
end
