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
    end
  end
end
