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

  LABELS = {
    'bolt'          => 'Błyskawica',
    'carrot'        => 'Marchewka',
    'carrotStar'    => 'Marchewka z gwiazdą',
    'chat'          => 'Rozmowa',
    'chev1'         => 'Belka',
    'chev2'         => 'Podwójna belka',
    'clock'         => 'Zegar',
    'compass'       => 'Kompas',
    'crew'          => 'Załoga',
    'crown'         => 'Korona',
    'flask'         => 'Kolba',
    'heartPlus'     => 'Serce z plusem',
    'hourglass'     => 'Klepsydra',
    'note'          => 'Koperta',
    'paperCheck'    => 'Kartka z ptaszkiem',
    'papers3'       => 'Trzy kartki',
    'papers3shield' => 'Trzy kartki z tarczą',
    'percent'       => 'Procent',
    'rabbit'        => 'Królik',
    'retake'        => 'Kartka ze strzałką',
    'rocket'        => 'Rakieta',
    'shield'        => 'Tarcza',
    'starPlus'      => 'Gwiazda z gwiazdką',
    'starTrail'     => 'Gwiazda ze smugą',
    'wrench'        => 'Klucz',
  }.freeze

  class << self
    def dir = 'glyphs'
    def labels = LABELS
  end
end
