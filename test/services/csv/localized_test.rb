# frozen_string_literal: true

require 'test_helper'

module Csv
  class LocalizedTest < ActiveSupport::TestCase
    test 'record_invalid_message lists the error sentences without attribute names' do
      story_group = create(:story_group)
      create(:rank, story_group: story_group, name: 'Nowicjusz', required_currency_value: 0)
      rank = build(:rank, story_group: story_group, name: '', required_currency_value: 0)
      rank.validate

      I18n.with_locale(:pl) do
        assert_equal 'Plik zawiera nieprawidłowe dane: Podaj nazwę rangi. i Ranga Nowicjusz ma już próg 0. ' \
                     'Wybierz inny.',
                     Localized.record_invalid_message(rank)
      end
    end
  end
end
