# frozen_string_literal: true

class PresetSet
  class << self
    # Subclasses declare these two.
    def dir = raise(NotImplementedError, "#{name} must define .dir")
    def labels = {}.freeze

    # Falls back to the key so a preset added to the directory without a label
    # is still pickable rather than nameless.
    def label_for(key)
      labels.fetch(key.to_s, key.to_s)
    end

    # Everything on disk. Not a hand-written list: a preset that exists but is
    # in no picker set is still renderable, which is what keeps an older
    # record showing its art after the picker's contents change.
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

    # Asset path, for the callers that want an <img> rather than inlined
    # markup — every GroupArt caller, and a preview thumbnail in a mail, where
    # no stylesheet runs and `currentColor` would resolve to nothing useful.
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
