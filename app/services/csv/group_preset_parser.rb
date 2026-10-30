# frozen_string_literal: true

module Csv
  class GroupPresetParser
    def initialize(files, story_group: nil)
      @files = files || {}
      @story_group = story_group
    end

    def call
      ranks = parse(RanksImport, :ranks)
      badges = parse(BadgesImport, :badges)
      items, warnings = items_file ? parse_items(ranks, badges) : [[], []]
      templates = parse(TemplatesImport, :templates)

      GroupPreset.new(ranks: ranks, badges: badges, items: items, templates: templates, warnings: warnings)
    end

    private

    def items_file = @files[:items]

    def parse_items(ranks, badges)
      importer = ItemsImport.new(file: items_file, ranks: ranks, badges: badges, story_group: @story_group)
      rows = importer.call

      [rows, importer.warnings]
    end

    def parse(klass, key)
      file = @files[key]
      return [] unless file

      klass.new(file: file).call
    end
  end
end
