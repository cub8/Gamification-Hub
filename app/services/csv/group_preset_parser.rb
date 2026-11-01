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
      templates, template_warnings = split_empty_templates(parse(TemplatesImport, :templates))

      preset = GroupPreset.new(ranks: ranks, badges: badges, items: items, templates: templates,
                               warnings: warnings + template_warnings,)
      preset.with(warnings: preset.warnings + duplicate_warnings(preset))
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

    # A template without categories cannot be used (the app requires at least one), so it is skipped.
    def split_empty_templates(templates)
      empty, usable = templates.partition { |template| template.categories.empty? }
      warnings = empty.map { |template| I18n.t('shared.csv_import.template_without_categories', name: template.name) }

      [usable, warnings]
    end

    def duplicate_warnings(preset)
      return [] unless @story_group&.persisted?

      [
        duplicates(:rank,     preset.ranks,     @story_group.ranks.pluck(:name)),
        duplicates(:badge,    preset.badges,    @story_group.badges.kept.pluck(:name)),
        duplicates(:item,     preset.items,     @story_group.items.kept.pluck(:name)),
        duplicates(:template, preset.templates, @story_group.activity_group_templates.kept.pluck(:base_name)),
      ].flatten
    end

    def duplicates(kind, rows, existing_names)
      existing = existing_names.to_set { |name| name.to_s.strip.downcase }

      rows.filter_map do |row|
        next unless existing.include?(row.name.to_s.strip.downcase)

        I18n.t("shared.csv_import.duplicate_#{kind}", name: row.name)
      end
    end
  end
end
