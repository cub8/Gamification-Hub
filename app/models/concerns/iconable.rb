# frozen_string_literal: true

module Iconable
  extend ActiveSupport::Concern

  ACCEPTABLE_ICON_TYPES = ['image/gif', 'image/jpeg', 'image/png'].freeze

  class_methods do
    def has_icon_art(attribute, glyphs:, glyph_message: 'Nieznana grafika.', required: true)
      has_one_attached attribute

      glyph_attribute      = :"#{attribute}_glyph"
      art_method           = icon_art_method_name(attribute)
      upload_method        = :"#{art_method.to_s.sub(/art\z/, 'upload?')}"
      acceptable_validator = :"acceptable_#{attribute}"
      art_chosen_validator = :"#{attribute}_art_chosen"

      validates glyph_attribute, inclusion: { in: glyphs, message: glyph_message }, allow_nil: true

      define_icon_content_type_validator(acceptable_validator, attribute)
      define_icon_art_chosen_validator(art_chosen_validator, attribute, glyph_attribute)
      define_icon_art_reader(art_method, attribute, glyph_attribute)
      define_icon_upload_predicate(upload_method, art_method)

      validate acceptable_validator
      validate art_chosen_validator if required
    end

    private

    # :icon -> :art, :badge_icon -> :badge_art
    def icon_art_method_name(attribute)
      return :art if attribute == :icon

      :"#{attribute.to_s.delete_suffix('_icon')}_art"
    end

    def define_icon_content_type_validator(validator_name, attribute)
      define_method(validator_name) do
        attachment = public_send(attribute)
        next unless attachment.attached?
        next if Iconable::ACCEPTABLE_ICON_TYPES.include?(attachment.content_type)

        errors.add(attribute, 'Grafika musi być plikiem GIF, JPG lub PNG.')
      end
    end

    def define_icon_art_chosen_validator(validator_name, attribute, glyph_attribute)
      define_method(validator_name) do
        next if public_send(glyph_attribute).present? || public_send(attribute).attached?

        errors.add(glyph_attribute, 'Wybierz gotową grafikę albo wgraj własną.')
      end
    end

    # Returns the chosen glyph, :upload if a file was attached instead, or nil if nothing was chosen yet.
    def define_icon_art_reader(art_method, attribute, glyph_attribute)
      define_method(art_method) do
        public_send(glyph_attribute).presence || (public_send(attribute).attached? ? :upload : nil)
      end
    end

    def define_icon_upload_predicate(upload_method, art_method)
      define_method(upload_method) do
        public_send(art_method) == :upload
      end
    end
  end
end
