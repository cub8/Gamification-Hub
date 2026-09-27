# frozen_string_literal: true

class PresetSet
  class << self
    def dir = raise(NotImplementedError, "#{name} must define .dir")
    def labels = {}.freeze

    def label_for(key)
      labels.fetch(key.to_s, key.to_s)
    end

    def all
      @all ||= Dir.children(Rails.root.join('app/assets/images', dir))
                  .grep(/\.svg\z/)
                  .map { |file| File.basename(file, '.svg') }
                  .sort
                  .freeze
    end

    def include?(key)
      all.include?(key.to_s)
    end

    def asset_for(key)
      "#{dir}/#{key}.svg"
    end

    def file_for(key)
      Rails.root.join('app/assets/images', dir, "#{key}.svg")
    end

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
