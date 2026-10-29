# frozen_string_literal: true

class Glyphs < PresetSet
  RANK = %w[
    chev1 chev2 rocket crown carrotStar shield starPlus compass crew bolt
  ].freeze

  BADGE = %w[
    rabbit rocket carrot compass starTrail wrench bolt crew crown shield heartPlus starPlus
  ].freeze

  ITEM = %w[
    shield hourglass chat retake percent paperCheck heartPlus note clock papers3 starPlus flask
  ].freeze

  class << self
    def dir = 'glyphs'
  end
end
