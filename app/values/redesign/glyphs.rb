# frozen_string_literal: true

module Redesign
  # The preset artwork ranks, badges and items offer.
  #
  # The mockup carries these as raw path data in one `GL` map
  # (js-expanded/00-shared.js:48-75) and picks a subset per entity
  # (30-br.js:13). Here each glyph is a real file under
  # app/assets/images/redesign/glyphs, generated from that map by
  # design/mockup-src/tools/extract_glyphs.mjs, and this object is the registry:
  # which keys exist, which an entity may use, and where the file is.
  #
  # The directory mechanics live in PresetSet, shared with the group's own two
  # sets. Only the contents are here.
  class Glyphs < PresetSet
    # Verbatim from the mockup's PRE map (30-br.js:13), order included: it is
    # the order the picker renders in, and it runs lowest rung to highest.
    RANK = %w[
      chev1 chev2 rocket crown carrotStar shield starPlus compass crew bolt
    ].freeze

    BADGE = %w[
      rabbit rocket carrot compass starTrail wrench bolt crew crown shield heartPlus starPlus
    ].freeze

    # 30-item.js:13. Deliberately the most literal set of the three: an item is
    # a thing you buy and use, so its art names the mechanic (a retake, a
    # deadline, a percentage) rather than a rank or a story beat.
    ITEM = %w[
      shield hourglass chat retake percent paperCheck heartPlus note clock papers3 starPlus flask
    ].freeze

    # What each glyph shows, in Polish. The picker is a radio group and this is
    # its only text — the mockup labels its tiles with the raw key ("Grafika
    # chev1", 30-br.js:27), which tells a screen reader nothing.
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
      def dir = 'redesign/glyphs'
      def labels = LABELS
    end
  end
end
