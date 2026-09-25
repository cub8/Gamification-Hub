# frozen_string_literal: true

# The preset covers a story group offers ("Grafika grupy").
#
# Scenes, not glyphs: 160x90, full colour, and cut to the card by
# `preserveAspectRatio="xMidYMid slice"`. That is the whole reason this is a
# separate set from Glyphs rather than more keys in it — a glyph is one shape
# tinted by `currentColor`, and these carry their own palette, so they render
# as an <img> (ApplicationHelper#gh_group_art) and never inlined.
#
# Generated from the wizard's ART map by
# design/mockup-src/tools/extract_group_art.mjs. The mockup's `rabbits` preset
# is deliberately absent: it is a stock photograph rather than art drawn for
# this app.
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
