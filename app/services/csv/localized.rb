# frozen_string_literal: true

module Csv
  module Localized
    class << self
      def current(key) = I18n.t(key)

      def aliases(key)
        locales = I18n.available_locales.map { |locale| I18n.t(key, locale: locale) }
        locales.uniq
      end

      def column(row, key)
        values = aliases(key).filter_map { |header| row[header] }
        values.first
      end

      def column_names(scope, keys)
        keys.map { |key| current("#{scope}.csv_columns.#{key}") }
      end

      # The models' messages are whole sentences ("Podaj nazwę rangi."), as the forms show them, so the
      # attribute name that full_messages would prepend is left out.
      def record_invalid_message(record)
        errors = ApplicationController.helpers.gh_and_list(record.errors.map(&:message))
        I18n.t('shared.csv_import.invalid_data', errors: errors)
      end
    end
  end
end
