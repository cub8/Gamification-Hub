# frozen_string_literal: true

module Redesign
  # The preset artwork every image field offers.
  #
  # The mockup carries these as raw path data in one `GL` map
  # (js-expanded/00-shared.js:48-75) and picks a subset per entity
  # (30-br.js:13). Here each glyph is a real file under
  # app/assets/images/redesign/glyphs, generated from that map by
  # design/mockup-src/tools/extract_glyphs.mjs, and this object is the registry:
  # which keys exist, which an entity may use, and where the file is.
  #
  # Read-only and database-free, so `values`. Rendering lives in
  # RedesignHelper#gh_glyph.
  #
  # DECISIONS.md:69 — "Real icon set later (use current presets for now)" — so
  # expect the files to be replaced wholesale. Records store the KEY, which is
  # what makes that swap possible without touching a single row.
  class Glyphs
    DIR = 'redesign/glyphs'

    # Verbatim from the mockup's PRE map (30-br.js:13), order included: it is
    # the order the picker renders in, and it runs lowest rung to highest.
    RANK = %w[
      chev1 chev2 rocket crown carrotStar shield starPlus compass crew bolt
    ].freeze

    BADGE = %w[
      rabbit rocket carrot compass starTrail wrench bolt crew crown shield heartPlus starPlus
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
      # Falls back to the key so a glyph added to the directory without a label
      # is still pickable rather than nameless.
      def label_for(key)
        LABELS.fetch(key.to_s, key.to_s)
      end

      # Everything on disk. Not a hand-written list: a glyph that exists but is
      # in no preset set is still renderable, which is what keeps an older
      # record showing its art after the picker's contents change.
      def all
        @all ||= Dir.children(Rails.root.join('app/assets/images', DIR))
                    .grep(/\.svg\z/)
                    .map { |file| File.basename(file, '.svg') }
                    .sort
                    .freeze
      end

      def include?(key)
        all.include?(key.to_s)
      end

      # Asset path, for the rare caller that wants an <img> rather than the
      # inlined markup — a preview thumbnail in a mail, say, where no stylesheet
      # runs and `currentColor` would resolve to nothing useful.
      def asset_for(key)
        "#{DIR}/#{key}.svg"
      end

      def file_for(key)
        Rails.root.join('app/assets/images', DIR, "#{key}.svg")
      end

      # The paths inside the file, without its <svg> wrapper — RedesignHelper
      # writes its own so it can put a class and the ARIA on it.
      #
      # Cached outside development, where the files are generated artefacts that
      # change only when the icon set is replaced. In development they are
      # re-read so a regenerated glyph shows up without a restart.
      def markup(key)
        return read(key) if Rails.env.development?

        @markup ||= {}
        @markup[key.to_s] ||= read(key)
      end

      private

      def read(key)
        return unless include?(key)

        file_for(key).read[%r{<svg[^>]*>(.*)</svg>}m, 1]
      end
    end
  end
end
